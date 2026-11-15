# Wires home-manager into nix-darwin, so the user layer (../../home) ships
# with the system. `useGlobalPkgs` and `useUserPackages` keep both layers on
# the one nixpkgs instance, and a file in the way of a managed one is renamed
# with a .backup extension instead of failing activation.
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

  ## Shared modules
  # The personal-constants module is evaluated a second time inside
  # home-manager, so the values this host resolved are handed over: an
  # override made on the nix-darwin side applies to both. mcp-servers-nix's
  # module comes along for home/mcp.nix.
  home-manager.sharedModules = [
    ../../modules/naitokosuke
    { inherit (config) naitokosuke; }
    inputs.mcp-servers-nix.homeManagerModules.default
  ];

  ## The user's home
  # home-manager derives home.username / home.homeDirectory from users.users,
  # whose `home` defaults to null on nix-darwin (issue #321).
  users.users.${config.naitokosuke.username}.home = config.naitokosuke.homeDirectory;
  home-manager.users.${config.naitokosuke.username} = import ../../home;

  ## specialArgs
  # Forward nix-darwin's specialArgs so flake.nix stays the single source of
  # truth and home modules receive the flake `inputs` directly (issue #324).
  # nix-darwin injects its own modulesPath, which must not shadow
  # home-manager's.
  home-manager.extraSpecialArgs = removeAttrs specialArgs [ "modulesPath" ];
}
