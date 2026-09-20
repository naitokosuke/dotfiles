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

    settings.show_banner = false;

    shellAliases = common.aliases // {
      cl = "^clear"; # `^` runs the external command, not Nushell's builtin
    };

    environmentVariables = common.envVars // {
      HOMEBREW_FORBIDDEN_FORMULAE = lib.concatStringsSep " " common.homebrewForbiddenFormulae;
    };

    # env.nu runs before config.nu
    extraEnv = ''
      $env.PATH = ($env.PATH | split row (char esep))

      # `path add` prepends, so these end up in reverse order
      use std/util "path add"

      ${lib.concatMapStringsSep "\n" (p: "path add \"${p}\"") common.pathEntries}
      path add ($env.HOME | path join ".nix-profile" "bin")
    '';

    extraConfig = ''
      use ${inputs.nu-scripts}/custom-completions/git/git-completions.nu *
      use ${inputs.nu-scripts}/custom-completions/gh/gh-completions.nu *
      use ${inputs.nu-scripts}/custom-completions/nix/nix-completions.nu *
      use ${inputs.nu-scripts}/custom-completions/pnpm/pnpm-completions.nu *
      use ${inputs.nu-scripts}/custom-completions/rg/rg-completions.nu *

      def --env mkcd [dir: string] {
        mkdir $dir
        cd $dir
      }

      # A command, not an alias, because Nushell aliases cannot contain pipelines
      def cpwd [] {
        pwd | pbcopy
      }

      if ($env.VSCODE_GIT_IPC_HANDLE? | is-empty) and ($env.TERM_PROGRAM? != "vscode") {
        cd ${config.naitokosuke.srcDirectory}/github.com/${config.home.username}
      }
    '';
  };
}
