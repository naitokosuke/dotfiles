# Adrafinil (cask in hosts/common/homebrew.nix) keeps the Mac awake only while
# an agent is working. Everything that runs its CLI is declared here, and tied
# to the cask through ./required-casks.nix: drop the cask and evaluation fails,
# instead of the hooks silently doing nothing and the server entry pointing at
# nothing.
{ lib, ... }:

let
  # Inside the app bundle, so it cannot come from the store.
  # /usr/local/bin/adrafinil is not used: the app only creates it
  # asynchronously at launch.
  cli = "/Applications/Adrafinil.app/Contents/Helpers/adrafinil";

  hook =
    {
      command,
      matcher ? null,
    }:
    [
      (
        {
          hooks = [
            {
              type = "command";
              inherit command;
            }
          ];
        }
        // lib.optionalAttrs (matcher != null) { inherit matcher; }
      )
    ];
  # stdin `session_id` wins over the env var, which is only the fallback.
  turn = op: "${cli} ${op} $CLAUDE_CODE_SESSION_ID --tool claude-code";
  # Keyed on the sub-agent's `agent_id` from stdin, so a backgrounded
  # sub-agent stays held after the parent turn's Stop.
  subagent = op: "${cli} ${op} --tool claude-code --subagent";
in
{
  naitokosuke.requiredCasks.adrafinil = "home/adrafinil.nix runs the Adrafinil CLI";

  # The app's one-click installer writes these hooks into
  # ~/.claude/settings.json, which is a read-only store symlink here.
  #
  # Hand-maintained copy of ClaudeCodeIntegration.swift at v1.7.0: the app
  # self-updates past the flake.lock pin, so re-check upstream when it does.
  # The commands must match upstream byte for byte — Adrafinil recognises its
  # hooks by command and compares them verbatim, so Settings → Agents reports
  # Claude Code as connected without the `_adrafinil` marker.
  programs.claude-code.settings.hooks = {
    UserPromptSubmit = hook { command = turn "acquire"; };
    Stop = hook { command = turn "release"; };
    # Esc-interrupt fires no Stop; this is a best-effort fast-path release.
    Notification = hook {
      command = turn "release";
      matcher = "idle_prompt";
    };
    SubagentStart = hook { command = subagent "acquire"; };
    SubagentStop = hook { command = subagent "release"; };
    # `/clear` and clear-context plan approval retire the session in-process
    # without a Stop: release the old id, and hold the new one whose plan
    # run skips UserPromptSubmit.
    SessionEnd = hook { command = turn "release"; };
    SessionStart = hook {
      command = turn "acquire";
      matcher = "clear";
    };
  };

  # The `keep_awake` tool, so an agent can hold the Mac awake for work that
  # outlives its turn (e.g. background shells), which the hooks do not cover.
  # Same entry upstream's installer writes to ~/.claude.json. Adrafinil only
  # inspects that file, so its Settings → Agents tab still reports the MCP
  # server as not installed.
  mcp-servers.settings.servers.adrafinil = {
    command = cli;
    args = [
      "mcp"
      "--tool"
      "claude-code"
    ];
  };
}
