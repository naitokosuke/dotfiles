# The personal constants the rest of the tree reads as `config.naitokosuke.*`,
# declared once as typed options instead of literals copied around. The module
# is loaded into both nix-darwin (flake.nix) and home-manager
# (hosts/common/home-manager.nix), so both trees resolve the same values.
{ config, lib, ... }:

let
  inherit (lib) literalExpression mkOption types;
  cfg = config.naitokosuke;
in
{
  options.naitokosuke = {
    ## Identity
    # Defaults rather than definitions, so a host overrides one with a plain
    # assignment (#552).
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
    # `homeDirectory` follows `username`, and `srcDirectory` is the one root
    # ghq, gwq and nh build their paths from. `githubDirectory` goes one step
    # further down ghq's layout to this user's own repositories, so
    # home/nh.nix and home/zsh.nix read one option instead of each assembling
    # the path. Overriding `username` on a host moves all of them.
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
