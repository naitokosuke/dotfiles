# nh rebuilds with nix-output-monitor and shows the closure diff before
# activating. `programs.nh.clean` is left off since on Darwin it only cleans user profiles;
# store GC runs as a root `nh clean all` daemon in hosts/common/nix.nix.
{ config, ... }:

{
  ## Pointing nh at this flake
  # So `nh darwin switch` needs no --flake argument.
  programs.nh = {
    enable = true;
    darwinFlake = "${config.naitokosuke.githubDirectory}/dotfiles";
  };
}
