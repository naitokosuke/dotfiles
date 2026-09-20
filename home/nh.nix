# `programs.nh.clean` is left off since on Darwin it only cleans user profiles;
# store GC runs as a root `nh clean all` daemon in hosts/common/nix.nix.
{ config, ... }:

let
  darwinFlake = "${config.naitokosuke.srcDirectory}/github.com/${config.home.username}/dotfiles";
in
{
  programs.nh = {
    enable = true;
    inherit darwinFlake;
  };

  # home.sessionVariables only reaches zsh; Nushell needs it set explicitly.
  programs.nushell.environmentVariables.NH_DARWIN_FLAKE = darwinFlake;
}
