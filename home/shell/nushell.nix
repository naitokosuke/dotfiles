# Nushell configuration
#
# Nushell is used as the interactive shell in Ghostty terminal.
# Non-POSIX shell with structured data and modern features.
#
# Note: Claude Code and other IDE integrations use zsh (login shell),
# so PATH and environment variables are also configured for zsh
# (home.sessionPath in default.nix, the rest in zsh.nix).
{
  config,
  inputs,
  lib,
  ...
}:

let
  common = import ./common.nix { inherit (config.naitokosuke) username; };
in
{
  programs.nushell = {
    enable = true;

    # Nushell settings (assigned to $env.config)
    settings.show_banner = false;

    # Shell aliases (inherit common + nushell-specific)
    shellAliases = common.aliases // {
      cl = "^clear"; # External command (nushell syntax)
    };

    # Environment variables
    environmentVariables = common.envVars // {
      HOMEBREW_FORBIDDEN_FORMULAE = lib.concatStringsSep " " common.homebrewForbiddenFormulae;
    };

    # Extra env configuration (env.nu) - runs before config.nu
    extraEnv = ''
      # Convert PATH from string to list
      $env.PATH = ($env.PATH | split row (char esep))

      # Add paths using std path add (prepends by default)
      use std/util "path add"

      # Add paths from common config
      ${lib.concatMapStringsSep "\n" (p: "path add \"${p}\"") common.pathEntries}
      path add ($env.HOME | path join ".nix-profile" "bin")
    '';

    # Extra configuration (config.nu)
    extraConfig = ''
      # Completions from nu_scripts
      use ${inputs.nu-scripts}/custom-completions/git/git-completions.nu *
      use ${inputs.nu-scripts}/custom-completions/gh/gh-completions.nu *
      use ${inputs.nu-scripts}/custom-completions/nix/nix-completions.nu *
      use ${inputs.nu-scripts}/custom-completions/pnpm/pnpm-completions.nu *
      use ${inputs.nu-scripts}/custom-completions/rg/rg-completions.nu *

      # Custom function: mkcd
      def --env mkcd [dir: string] {
        mkdir $dir
        cd $dir
      }

      # Default directory on terminal launch (non-VSCode)
      if ($env.VSCODE_GIT_IPC_HANDLE? | is-empty) and ($env.TERM_PROGRAM? != "vscode") {
        cd ${config.home.homeDirectory}/src/github.com/${config.home.username}
      }
    '';
  };
}
