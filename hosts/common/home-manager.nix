{
  config,
  inputs,
  specialArgs,
  ...
}:

{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";
  home-manager.sharedModules = [
    ../../modules/naitokosuke
    inputs.mcp-servers-nix.homeManagerModules.default
  ];
  # home-manager derives home.username / home.homeDirectory from users.users,
  # whose `home` defaults to null on nix-darwin (issue #321).
  users.users.${config.naitokosuke.username}.home = config.naitokosuke.homeDirectory;
  home-manager.users.${config.naitokosuke.username} = import ../../home;
  # Forward nix-darwin's specialArgs so flake.nix stays the single source of
  # truth (issue #324). nix-darwin injects its own modulesPath, which must not
  # shadow home-manager's.
  home-manager.extraSpecialArgs = removeAttrs specialArgs [ "modulesPath" ];
}
