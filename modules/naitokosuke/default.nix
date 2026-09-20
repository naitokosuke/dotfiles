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
  };

  config.naitokosuke = {
    username = "naitokosuke";
    fullName = "naitokosuke";
    email = "kosuke.naito.engineer@gmail.com";
    homeDirectory = "/Users/naitokosuke";
    srcDirectory = "${config.naitokosuke.homeDirectory}/src";
  };
}
