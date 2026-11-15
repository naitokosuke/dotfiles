# Claude Code's user-level configuration. settings.json, CLAUDE.md, the rules
# and the skills are read-only store symlinks, so Nix is the single source of
# truth and runtime edits are not persisted back. The binary comes from
# ./claude-sandbox.nix and the MCP integration from ./mcp.nix.
{
  inputs,
  ...
}:

{
  naitokosuke.requiredCasks.visual-studio-code = "home/claude.nix runs `code` in its plan hook";

  programs.claude-code.enable = true;

  programs.claude-code.settings = {
    ## Preferences
    # Theme, editor mode, notifications and Japanese spinner verbs. The binary
    # comes from the store (./claude-sandbox.nix), so nothing may update it in
    # place: `env` turns off the auto-updater and the installation checks,
    # which are the variables Claude Code reads for that. The llm-agents
    # wrapper exports them too; these also cover a `claude` started without it
    # (#485).
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
    ## Permissions
    # Denied outright rather than asked: reading credentials, wiping / or ~,
    # force-pushing, and raw curl / wget in favour of WebFetch with an explicit
    # domain, plus a tongue-in-cheek ban on perl and python.
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
    ## Plan hook
    # A PreToolUse hook on ExitPlanMode opens the newest plan in VS Code, so a
    # plan can be read in the editor before it is approved. `code` comes from
    # the cask through /opt/homebrew/bin (environment.systemPath in
    # hosts/common/homebrew.nix), which `naitokosuke.requiredCasks` above ties
    # this module to. With no plan file the glob would be passed through
    # literally, so the match is tested before opening anything — the hook is
    # best-effort, and a failure here is quiet enough to stay unnoticed.
    # ./adrafinil.nix and ./claude-rm-guard merge their hooks in alongside.
    hooks = {
      PreToolUse = [
        {
          matcher = "ExitPlanMode";
          hooks = [
            {
              type = "command";
              command = ''plan=$(ls -t ~/.claude/plans/*.md 2>/dev/null | head -1); [ -n "$plan" ] && code "$plan" || true'';
              timeout = 5;
            }
          ];
        }
      ];
    };
  };

  ## Rules and skills
  # CLAUDE.md and the rules live in ./claude-context and are installed from
  # the store, so they cannot dangle (#535). Skills come from the locked
  # skill-skill-skill input, the single source for both their names and their
  # content, so a skill change arrives with
  #   nix flake update skill-skill-skill
  # home-manager links the files one by one, which leaves room for the MCP
  # plugin it installs into the same directory.
  programs.claude-code.context = ./claude-context/CLAUDE.md;
  programs.claude-code.rulesDir = ./claude-context/rules;
  programs.claude-code.skills = "${inputs.skill-skill-skill}/.claude/skills";
}
