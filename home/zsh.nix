# Zsh is the only shell: the login shell for IDE integrations and SSH, and
# the interactive shell in Ghostty. PATH comes from nix-darwin's /etc/zshenv
# (hosts/common/nix.nix).
{
  config,
  lib,
  ...
}:

let
  ## Forbidden formulae
  # Packages managed by Nix - prevent accidental brew install
  # See: https://github.com/Homebrew/brew/issues/19939
  homebrewForbiddenFormulae = [
    "bun"
    "claude"
    "deno"
    "fd"
    "fzf"
    "gh"
    "git"
    "node"
    "npm"
    "pip"
    "pnpm"
    "python"
    "python3"
    "ripgrep"
    "vim"
    "yarn"
  ];
in
{
  ## Environment
  # The forbidden formulae above are exported, so `brew install` refuses them.
  home.sessionVariables = {
    EDITOR = "vim";
    HOMEBREW_FORBIDDEN_FORMULAE = lib.concatStringsSep " " homebrewForbiddenFormulae;
  };

  programs.zsh = {
    enable = true;

    ## Aliases
    # `cpwd` copies the current directory to the clipboard.
    shellAliases = {
      l = "ls";
      la = "ls -la";
      ll = "ls -l";
      ":q" = "exit";
      cl = "clear";
      cpwd = "pwd | pbcopy";
    };

    ## Interactive startup
    # `mkcd` makes a directory and enters it, and a new terminal starts in this
    # user's GitHub directory unless VS Code opened it.
    initContent = ''
      mkcd() {
        mkdir -p "$1" && cd "$1"
      }

      # A new terminal starts in the ghq directory unless VS Code opened it.
      if [[ -z $VSCODE_GIT_IPC_HANDLE && $TERM_PROGRAM != vscode ]]; then
        cd ${lib.escapeShellArg config.naitokosuke.githubDirectory}
      fi
    '';
  };
}
