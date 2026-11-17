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

  ## nhup and nhu
  # Update every flake input, rebuild with `nh darwin <action>`, and push the
  # new lock (#629): nhup switches, nhu only builds, so a lock that does not
  # build is never pushed either way. Arguments go to nh. Commands of their
  # own rather than an `nh` shell function: nh has no external subcommands,
  # and shadowing it would break outside interactive shells. The git steps run
  # against the flake checkout, so they work from any directory.
  mkUpdate =
    name: action:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [
        config.programs.nh.package
        pkgs.git
      ];
      text = ''
        nh darwin ${action} -u "$@"
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

  home.packages = [
    (mkUpdate "nhup" "switch")
    (mkUpdate "nhu" "build")
  ];
}
