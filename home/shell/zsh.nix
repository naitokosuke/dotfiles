# Zsh configuration (login shell)
#
# Zsh is the login shell on macOS, used by:
# - Claude Code (VSCode extension)
# - Other IDE integrations
# - SSH sessions
# - Terminal emulators (as login shell)
#
# Nushell is used as the interactive shell in Ghostty terminal,
# but Zsh handles login shell responsibilities.
#
# PATH (home.sessionPath, set in ./default.nix) is loaded in .zprofile
# (not .zshenv) per Nix best practices.
# See: https://github.com/nix-community/home-manager/issues/2991
{
  config,
  lib,
  ...
}:

let
  common = import ./common.nix { inherit (config.naitokosuke) username; };
in
{
  programs.zsh = {
    enable = true;

    # Environment variables
    sessionVariables = common.envVars // {
      HOMEBREW_FORBIDDEN_FORMULAE = lib.concatStringsSep " " common.homebrewForbiddenFormulae;
    };

    # Shell aliases (inherit common + zsh-specific)
    shellAliases = common.aliases // {
      cl = "clear";
      cpwd = "pwd | pbcopy";
    };
  };
}
