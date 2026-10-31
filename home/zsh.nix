# Zsh is the only shell: the login shell for IDE integrations and SSH, and
# the interactive shell in Ghostty.
#
# PATH (home.sessionPath) is loaded in .zprofile (not .zshenv) per Nix best
# practices. See: https://github.com/nix-community/home-manager/issues/2991
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
  # One entry per reason, each declared once, highest priority first.
  # home-manager is the only thing that puts the Nix directories on PATH:
  # `hosts/common/nix.nix` disables nix-darwin's zsh integration, so
  # /etc/zshenv sets no PATH. /usr/local/bin and /opt/homebrew/sbin used to be
  # here and were dropped in #483 — nothing this configuration depends on
  # lives in either.
  home.sessionPath = [
    "/etc/profiles/per-user/${config.home.username}/bin"
    "/run/current-system/sw/bin"
    "/nix/var/nix/profiles/default/bin"
    # Cask binaries: `code` for the plan hook in home/claude.nix, and Orca's
    # CLI.
    "/opt/homebrew/bin"
  ];

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
        cd ${config.naitokosuke.srcDirectory}/github.com/${config.home.username}
      fi
    '';
  };
}
