{
  lib,
  inputs,
  pkgs,
  ...
}:

{
  programs.claude-code.enable = true;

  programs.claude-code.settings = {
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
    # The binary comes from the store (see ./claude-sandbox.nix), so nothing may
    # update it in place — a second, unmanaged copy installing itself next to the
    # Nix-managed one is the failure this repository already hit twice with `vp`
    # (#413, #434). This env block is the mechanism Claude Code actually reads:
    # it checks `process.env.DISABLE_AUTOUPDATER`, and migrates the legacy
    # `autoUpdates` preference out of ~/.claude.json to exactly here. The
    # `installMethod` / `autoUpdates` keys this file used to set were never read
    # from settings.json at all and were dropped in #485.
    #
    # The llm-agents wrapper exports both variables itself, so these two lines
    # are a deliberate duplicate — they also cover a `claude` started without
    # that wrapper.
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

        # Regular push stays in `ask`/allow
        "Bash(git push --force:*)"
        "Bash(git push -f:*)"
        "Bash(git push * --force:*)"
        "Bash(git push * -f:*)"

        # Prefer WebFetch with explicit domain over raw curl/wget
        "Bash(curl:*)"
        "Bash(wget:*)"
      ];
    };
    hooks = {
      PreToolUse = [
        {
          matcher = "ExitPlanMode";
          hooks = [
            {
              type = "command";
              # Opens the newest plan in VS Code (installed by ./vscode.nix).
              # With no plan file the glob would be passed through literally,
              # so the match is tested before opening anything — the hook is
              # best-effort, and a failure here is quiet enough to stay
              # unnoticed.
              command = ''plan=$(ls -t ~/.claude/plans/*.md 2>/dev/null | head -1); [ -n "$plan" ] && ${lib.getExe pkgs.vscode} "$plan" || true'';
              timeout = 5;
            }
          ];
        }
      ];
    };
  };

  # Kept in this repository and installed from the store, so they cannot
  # dangle the way links into a separate, uncloned checkout did (#535).
  programs.claude-code.context = ./claude-context/CLAUDE.md;
  programs.claude-code.rulesDir = ./claude-context/rules;

  # The locked input is the single source for both the skill names and their
  # content, so a skill change arrives with
  #   nix flake update skill-skill-skill
  # home-manager links the files one by one, which leaves room for the MCP
  # plugin it installs into the same directory.
  programs.claude-code.skills = "${inputs.skill-skill-skill}/.claude/skills";
}
