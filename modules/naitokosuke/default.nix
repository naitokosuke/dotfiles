{ config, lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options.naitokosuke = {
    username = mkOption {
      type = types.str;
      description = "Primary user account name.";
    };
    fullName = mkOption {
      type = types.str;
      description = "Display name used for git commits and similar identity fields.";
    };
    email = mkOption {
      type = types.str;
      description = "Primary email address.";
    };
    homeDirectory = mkOption {
      type = types.str;
      description = "Absolute path to the primary user's home directory.";
    };
    srcDirectory = mkOption {
      type = types.str;
      description = "Root directory for source checkouts, shared by ghq and gwq.";
    };

    # Settings that must be identical in Nushell and Zsh. Options rather than a
    # plain attrset so they are readable off `config` like every other shared
    # constant here, and overridable per host (issue #483).
    shell = {
      homebrewForbiddenFormulae = mkOption {
        type = types.listOf types.str;
        visible = false;
        description = "Formulae `brew install` must refuse because Nix owns the binary.";
      };
      envVars = mkOption {
        type = types.attrsOf types.str;
        visible = false;
        description = "Environment variables exported by both shells.";
      };
      aliases = mkOption {
        type = types.attrsOf types.str;
        visible = false;
        description = "Aliases defined in both shells; POSIX-compatible syntax only.";
      };
      pathEntries = mkOption {
        type = types.listOf types.str;
        visible = false;
        description = "PATH entries in priority order — last is highest priority.";
      };
    };
  };

  config.naitokosuke = {
    username = "naitokosuke";
    fullName = "naitokosuke";
    email = "kosuke.naito.engineer@gmail.com";
    homeDirectory = "/Users/naitokosuke";
    srcDirectory = "${config.naitokosuke.homeDirectory}/src";

    shell = {
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

      envVars = {
        EDITOR = "vim";
      };

      aliases = {
        l = "ls";
        la = "ls -la";
        ll = "ls -l";
        ":q" = "exit";
        nid = "ni -D";
      };

      # One entry per reason, each declared once. home-manager is the only
      # thing that puts the Nix directories on either shell's PATH:
      # `hosts/common/nix.nix` disables nix-darwin's zsh integration, so
      # /etc/zshenv sets no PATH, and Ghostty starts `nu --login` directly
      # rather than through a login Zsh. /usr/local/bin and /opt/homebrew/sbin
      # used to be here and were dropped in #483 — nothing this configuration
      # depends on lives in either.
      pathEntries = [
        # Cask binaries: `code` for the plan hook in home/claude.nix, and
        # Orca's CLI.
        "/opt/homebrew/bin"
        "/nix/var/nix/profiles/default/bin"
        "/run/current-system/sw/bin"
        "/etc/profiles/per-user/${config.naitokosuke.username}/bin"
      ];
    };
  };
}
