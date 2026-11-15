# Per-project shells: a .envrc plus `direnv allow` loads the project's nix
# shell or devenv on cd. nix-direnv caches the evaluated environment and roots
# it against GC, so entering a project is instant after the first load.
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
