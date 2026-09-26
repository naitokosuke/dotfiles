# Zsh is the login shell (IDE integrations, SSH); Nushell is only the
# interactive shell in Ghostty, so both need the same environment.
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
  inherit (config.naitokosuke) shell;
in
{
  programs.zsh = {
    enable = true;

    sessionVariables = shell.envVars // {
      HOMEBREW_FORBIDDEN_FORMULAE = lib.concatStringsSep " " shell.homebrewForbiddenFormulae;
    };

    shellAliases = shell.aliases // {
      cl = "clear";
      cpwd = "pwd | pbcopy";
    };
  };
}
