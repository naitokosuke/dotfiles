# Zsh is the only shell: the login shell for IDE integrations and SSH, and
# the interactive shell in Ghostty. PATH comes from nix-darwin's /etc/zshenv
# (hosts/common/nix.nix).
{
  config,
  lib,
  ...
}:

let
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
  home.sessionVariables = {
    EDITOR = "vim";
    HOMEBREW_FORBIDDEN_FORMULAE = lib.concatStringsSep " " homebrewForbiddenFormulae;
  };

  programs.zsh = {
    enable = true;

    shellAliases = {
      l = "ls";
      la = "ls -la";
      ll = "ls -l";
      ":q" = "exit";
      cl = "clear";
      cpwd = "pwd | pbcopy";
    };

    initContent = ''
      mkcd() {
        mkdir -p "$1" && cd "$1"
      }

      # A new terminal starts in the ghq directory unless VS Code opened it.
      if [[ -z $VSCODE_GIT_IPC_HANDLE && $TERM_PROGRAM != vscode ]]; then
        cd ${config.naitokosuke.githubDirectory}
      fi
    '';
  };
}
