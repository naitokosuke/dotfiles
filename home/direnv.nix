# direnv with nix-direnv: a project's .envrc loads its Nix or devenv shell on
# `cd`, cached and rooted against garbage collection.
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
