# nh configuration
#
# nh is a Nix CLI helper that wraps rebuilds with nix-output-monitor
# progress and a closure diff (nvd) before activation.
# https://github.com/nix-community/nh
#
# Try it with `nh darwin switch` (picks darwinConfigurations.<hostname>).
# Store GC runs as a root `nh clean all` daemon in hosts/common/nix.nix;
# `programs.nh.clean` is left off since on Darwin it only cleans user profiles.
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
