{ pkgs, ... }:

{
  programs.direnv = {
    enable = true;
    nix-direnv = {
      enable = true;
      # The default nix-direnv runs CppNix; this one runs the Lix the system
      # uses (hosts/common/nix.nix, #561).
      package = pkgs.lixPackageSets.latest.nix-direnv;
    };
  };
}
