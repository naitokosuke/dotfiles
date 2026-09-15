{
  config,
  lib,
  inputs,
  ...
}:

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
    hooks = {
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
