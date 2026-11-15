# The system layer shared by every Mac; each concern is a sibling module.
{
  imports = [
    ./dock.nix
    ./finder.nix
    ./fonts.nix
    ./home-manager.nix
    ./homebrew.nix
    ./keyboard.nix
    ./nix.nix
    ./nsglobaldomain.nix
    ./packages.nix
    ./screen_capture.nix
    ./xcode.nix
  ];
}
