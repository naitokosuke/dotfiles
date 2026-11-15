# nh wraps rebuilds with nix-output-monitor progress and a closure diff.
# `darwinFlake` is this checkout, so `nh darwin switch` picks
# `darwinConfigurations.<hostname>` without a --flake argument.
# `programs.nh.clean` is left off since on Darwin it only cleans user profiles;
# store GC runs as a root `nh clean all` daemon in hosts/common/nix.nix.
{ config, ... }:

{
  programs.nh = {
    enable = true;
    darwinFlake = "${config.naitokosuke.githubDirectory}/dotfiles";
  };
}
