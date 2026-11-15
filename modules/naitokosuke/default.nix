# The personal values the rest of the tree reads as config.naitokosuke.*
# instead of hardcoding them. Loaded into both nix-darwin and home-manager, and
# overridable per host with a plain assignment (#552).
{ config, lib, ... }:

let
  inherit (lib) literalExpression mkOption types;
  cfg = config.naitokosuke;
in
{
  options.naitokosuke = {
    ## Identity
    # Typed options with defaults, so a host overrides one by assigning it.
    username = mkOption {
      type = types.str;
      default = "naitokosuke";
      description = "Primary user account name.";
    };
    fullName = mkOption {
      type = types.str;
      default = "naitokosuke";
      description = "Display name used for git commits and similar identity fields.";
    };
    email = mkOption {
      type = types.str;
      default = "kosuke.naito.engineer@gmail.com";
      description = "Primary email address.";
    };
    ## Derived directories
    # Each directory derives from the one above it, so overriding `username`
    # moves them all. srcDirectory is the root ghq, gwq and nh build on.
    homeDirectory = mkOption {
      type = types.str;
      default = "/Users/${cfg.username}";
      defaultText = literalExpression ''"/Users/''${config.naitokosuke.username}"'';
      description = "Absolute path to the primary user's home directory.";
    };
    srcDirectory = mkOption {
      type = types.str;
      default = "${cfg.homeDirectory}/src";
      defaultText = literalExpression ''"''${config.naitokosuke.homeDirectory}/src"'';
      description = "Root directory for source checkouts, shared by ghq and gwq.";
    };
    githubDirectory = mkOption {
      type = types.str;
      default = "${cfg.srcDirectory}/github.com/${cfg.username}";
      defaultText = literalExpression ''"''${config.naitokosuke.srcDirectory}/github.com/''${config.naitokosuke.username}"'';
      description = "Directory under srcDirectory holding this user's own GitHub repositories, in ghq's layout: where new shells start, and where the dotfiles checkout is expected.";
    };
  };
}
