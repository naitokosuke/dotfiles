# Private or machine-local host definitions (e.g. work servers) should not
# live in this repository; put them in ~/.ssh/config.d/ instead, which is
# pulled in via the Include directive below.
{
  programs.ssh = {
    enable = true;

    enableDefaultConfig = false;

    includes = [ "config.d/*" ];

    settings."github.com" = {
      AddKeysToAgent = true;
      UseKeychain = true;
      IdentityFile = "~/.ssh/id_ed25519";
      IdentitiesOnly = true;
    };
  };
}
