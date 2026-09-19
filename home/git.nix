{
  config,
  ...
}:

{
  programs.git = {
    enable = true;
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
    # Sign commits and tags with the SSH key home/ssh.nix already uses for
    # GitHub. The public key must be registered on GitHub as a signing key.
    signing = {
      format = "ssh";
      key = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
      signByDefault = true;
    };
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
