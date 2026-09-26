{
  config,
  inputs,
  lib,
  ...
}:

let
  inherit (config.naitokosuke) shell;
in
{
  programs.nushell = {
    enable = true;

    settings.show_banner = false;

    shellAliases = shell.aliases // {
      cl = "^clear"; # `^` runs the external command, not Nushell's builtin
    };

    environmentVariables = shell.envVars // {
      HOMEBREW_FORBIDDEN_FORMULAE = lib.concatStringsSep " " shell.homebrewForbiddenFormulae;
    };

    # env.nu runs before config.nu. Ghostty starts `nu --login` directly rather
    # than through a login Zsh, so home.sessionPath never reaches Nushell and
    # this is where the same entries arrive in this shell.
    extraEnv = ''
      $env.PATH = ($env.PATH | split row (char esep))

      # `path add` prepends, so these end up in reverse order
      use std/util "path add"

      ${lib.concatMapStringsSep "\n" (p: "path add \"${p}\"") shell.pathEntries}
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
