{
  config,
  lib,
  inputs,
  ...
}:

let
  # Adrafinil (cask in hosts/common/homebrew.nix) keeps the Mac awake only
  # while an agent turn is running. Its one-click installer writes these hooks
  # into ~/.claude/settings.json, which is a read-only store symlink here, so
  # they are declared below instead.
  #
  # Hand-maintained copy of ClaudeCodeIntegration.swift at v1.7.0: the app
  # self-updates past the flake.lock pin, so re-check upstream when it does.
  # The commands must match upstream byte for byte — Adrafinil recognises its
  # hooks by command and compares them verbatim, so Settings → Agents reports
  # Claude Code as connected without the `_adrafinil` marker. The bundle path
  # is used instead of /usr/local/bin/adrafinil, which the app only creates
  # asynchronously at launch.
  adrafinil =
    let
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
      # Per-turn hold keyed on the session id (stdin `session_id` wins; the
      # env var is the fallback).
      turn = op: "${cli} ${op} $CLAUDE_CODE_SESSION_ID --tool claude-code";
      # Keyed on the sub-agent's `agent_id` from stdin, so a backgrounded
      # sub-agent stays held after the parent turn's Stop.
      subagent = op: "${cli} ${op} --tool claude-code --subagent";
    in
    {
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
in

{
  # settings.json is generated declaratively by programs.claude-code as a
  # read-only store symlink. Nix is the single source of truth; runtime edits
  # are not persisted back.
  programs.claude-code.settings = {
    installMethod = "unknown";
    autoUpdates = true;
    theme = "dark-daltonized";
    verbose = false;
    preferredNotifChannel = "auto";
    shiftEnterKeyBindingInstalled = true;
    editorMode = "normal";
    spinnerVerbs = {
      mode = "replace";
      verbs = [
        "考え中"
        "深く考え中"
        "実装中"
        "リファクタリング中"
        "調査中"
      ];
    };
    hasUsedBackslashReturn = true;
    autoCompactEnabled = true;
    diffTool = "auto";
    env = {
      DISABLE_AUTOUPDATER = "1";
      DISABLE_INSTALLATION_CHECKS = "1";
    };
    todoFeatureEnabled = true;
    messageIdleNotifThresholdMs = 60000;
    autoConnectIde = false;
    autoInstallIdeExtension = true;
    checkpointingEnabled = true;
    permissions = {
      deny = [
        # Joke: discourage legacy / non-preferred runtimes
        "Bash(perl:*)"
        "Bash(python:*)"
        "Bash(python3:*)"

        # Credentials and secrets (gitignore semantics, recursive)
        "Read(.env)"
        "Read(.env.*)"
        "Read(./secrets/**)"
        "Read(**/credentials.json)"
        "Read(~/.ssh/**)"
        "Read(~/.aws/**)"
        "Read(~/.gnupg/**)"

        # Destructive shell — root / home wipes still trip the circuit breaker,
        # but make it explicit
        "Bash(rm -rf /:*)"
        "Bash(rm -rf ~:*)"
        "Bash(rm -rf ~/:*)"

        # Force-push protection (regular push stays in `ask`/allow)
        "Bash(git push --force:*)"
        "Bash(git push -f:*)"
        "Bash(git push * --force:*)"
        "Bash(git push * -f:*)"

        # Prefer WebFetch with explicit domain over raw curl/wget
        "Bash(curl:*)"
        "Bash(wget:*)"
      ];
    };
    hooks = adrafinil // {
      PreToolUse = [
        {
          matcher = "ExitPlanMode";
          hooks = [
            {
              type = "command";
              command = ''code "$(ls -t ~/.claude/plans/*.md | head -1)"'';
              timeout = 5;
            }
          ];
        }
      ];
    };
  };

  # Claude Code rules, CLAUDE.md and skills - out-of-store symlinks into the
  # rule-rule-rule / skill-skill-skill repositories.
  #
  # Skills are linked one by one instead of linking ~/.claude/skills itself:
  # programs.claude-code installs its generated MCP plugin into
  # ~/.claude/skills/claude-code-home-manager, which fails with
  # "outside $HOME" when the directory is a symlink.
  home.file =
    let
      ghqRoot = "${config.naitokosuke.srcDirectory}/github.com/${config.home.username}";
      link = path: { source = config.lib.file.mkOutOfStoreSymlink "${ghqRoot}/${path}"; };
      # Skill names are discovered from the locked skill-skill-skill input
      # (pure eval cannot readDir the live working tree). The links themselves
      # still point at the working tree, so skill *content* stays live.
      # After adding/removing a skill: push it, then
      #   nix flake update skill-skill-skill
      skillNames = builtins.attrNames (
        lib.filterAttrs (_: type: type == "directory") (
          builtins.readDir "${inputs.skill-skill-skill}/.claude/skills"
        )
      );
      skillLinks = lib.listToAttrs (
        map (
          name: lib.nameValuePair ".claude/skills/${name}" (link "skill-skill-skill/.claude/skills/${name}")
        ) skillNames
      );
    in
    {
      ".claude/rules" = link "rule-rule-rule/rules";
      ".claude/CLAUDE.md" = link "rule-rule-rule/CLAUDE.md";
    }
    // skillLinks;
}
