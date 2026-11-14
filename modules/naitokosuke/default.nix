{ config, lib, ... }:

let
  inherit (lib) literalExpression mkOption types;
  cfg = config.naitokosuke;
in
{
  options.naitokosuke = {
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
      description = "Directory under srcDirectory holding this user's own GitHub repositories, in ghq's layout: where new shells start, and where the dotfiles and skills checkouts are expected.";
    };
  };
}
