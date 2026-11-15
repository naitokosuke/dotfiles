# Only what is safe to publish. `enableDefaultConfig = false` stops
# home-manager's implicit `Host *` defaults, and `includes` pulls private or
# machine-local host definitions (e.g. work servers) from ~/.ssh/config.d/,
# which stays out of this repository.
{ config, ... }:

{
  programs.ssh = {
    enable = true;

    enableDefaultConfig = false;

    includes = [ "config.d/*" ];

    ## github.com
    # A single ed25519 key, offered alone (`IdentitiesOnly`), added to the
    # agent on first use with its passphrase stored in the macOS Keychain.
    # ./git.nix signs commits with the same key.
    settings."github.com" = {
      AddKeysToAgent = true;
      UseKeychain = true;
      IdentityFile = "${config.home.homeDirectory}/.ssh/id_ed25519";
      IdentitiesOnly = true;
    };
  };
}
