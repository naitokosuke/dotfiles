# The system layer: every nix-darwin module that applies to each Mac. A new
# system-wide concern is a sibling file, imported here.
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
