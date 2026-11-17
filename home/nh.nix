# nh wraps rebuilds with nix-output-monitor progress and a closure diff.
# `darwinFlake` is this checkout, so `nh darwin switch` picks
# `darwinConfigurations.<hostname>` without a --flake argument.
# `programs.nh.clean` is left off since on Darwin it only cleans user profiles;
# store GC runs as a root `nh clean all` daemon in hosts/common/nix.nix.
{
  config,
  pkgs,
  ...
}:

let
  flake = "${config.naitokosuke.githubDirectory}/dotfiles";

  ## nhup
  # Updates every flake input, switches, and pushes the new lock (#629). A
  # command of its own rather than an `nh` shell function: nh has no external
  # subcommands, and shadowing it would break outside interactive shells. The
  # git steps run against the flake checkout, so it works from any directory.
  nhup = pkgs.writeShellApplication {
    name = "nhup";
    runtimeInputs = [
      config.programs.nh.package
      pkgs.git
    ];
    text = ''
      nh darwin switch -u
      git -C ${flake} add .
      git -C ${flake} commit -m "Update flake.lock"
      git -C ${flake} push
    '';
  };
in
{
  programs.nh = {
    enable = true;
    darwinFlake = flake;
  };

  home.packages = [ nhup ];
}
