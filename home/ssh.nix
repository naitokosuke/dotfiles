# Only what is safe to publish. Private or machine-local host definitions
# (e.g. work servers) should not live in this repository; put them in
# ~/.ssh/config.d/ instead, which is pulled in via the Include directive below.
{ config, ... }:

{
  programs.ssh = {
    enable = true;

    enableDefaultConfig = false;

    includes = [ "config.d/*" ];

    ## github.com
    # One key, offered alone, with its passphrase kept in the Keychain.
    settings."github.com" = {
      AddKeysToAgent = true;
      UseKeychain = true;
      IdentityFile = "${config.home.homeDirectory}/.ssh/id_ed25519";
      IdentitiesOnly = true;
    };
  };
}
