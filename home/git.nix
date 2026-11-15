# The user-global git config. The identity comes from `config.naitokosuke`, so
# the name and email are the same values the rest of the tree uses.
{
  config,
  ...
}:

{
  programs.git = {
    enable = true;
    ## Global ignores
    # Beyond .DS_Store and CodeTour's .tours: personal scratch files, VS Code's
    # file-nesting dummy, local Claude Code settings, and frog's friction logs.
    ignores = [
      ".tours"
      ".DS_Store"
      "*.memo.local.md"
      "___naito___"
      ".claude/settings.local.json"
      # Dummy file for VSCode file nesting. Nests config files under it to reduce clutter in project roots.
      # Related: https://github.com/naitokosuke/vscode-settings (explorer.fileNesting.patterns)
      "___config___"
      # frog friction logs (https://frog.fm) stay local by default. Kept as a
      # directory-level pattern so a repo that wants them tracked can re-include
      # with "!.agents/" in its own .gitignore (issue #385).
      ".agents/"
    ];
    ## Commit signing
    # Commits and tags are signed with the same SSH key ./ssh.nix uses for
    # GitHub, so GitHub marks them Verified. The public key must be registered
    # on GitHub as a signing key, the one step outside Nix (see the README).
    signing = {
      format = "ssh";
      key = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
      signByDefault = true;
    };
    ## Defaults
    # histogram diffs, zdiff3 conflict markers, rerere, rebase on pull with
    # autostash, `push.autoSetupRemote` and `fetch.prune`. `ghq.root` is the
    # shared source root, and GitHub HTTPS URLs are rewritten to SSH.
    settings = {
      user = {
        name = config.naitokosuke.fullName;
        email = config.naitokosuke.email;
      };
      branch.sort = "-committerdate";
      commit.verbose = true;
      core.editor = "vim";
      # Show non-ASCII (e.g. Japanese) filenames verbatim instead of octal escapes.
      core.quotepath = false;
      diff.algorithm = "histogram";
      fetch.prune = true;
      init.defaultBranch = "main";
      ghq.root = config.naitokosuke.srcDirectory;
      merge.conflictStyle = "zdiff3";
      pull.rebase = true;
      push.autoSetupRemote = true;
      rebase.autoStash = true;
      rerere.enabled = true;
      url."git@github.com:".insteadOf = "https://github.com/";
    };
  };
}
