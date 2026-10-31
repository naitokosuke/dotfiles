# `programs.nh.clean` is left off since on Darwin it only cleans user profiles;
# store GC runs as a root `nh clean all` daemon in hosts/common/nix.nix.
{ config, ... }:

{
  programs.nh = {
    enable = true;
    darwinFlake = "${config.naitokosuke.githubDirectory}/dotfiles";
  };
}
