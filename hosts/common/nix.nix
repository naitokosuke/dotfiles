{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

{
  # nix-darwin writes /etc/zsh*, which load the system environment and put
  # every profile's share/zsh on fpath, so packaged completions work (#544).
  # compinit and the prompt are left to home/zsh.nix and home/starship.nix.
  programs.zsh = {
    enable = true;
    enableGlobalCompInit = false;
    promptInit = "";
  };

  # nixd and devenv (./packages.nix) embed an evaluator and link the CppNix
  # libraries. nixpkgs' lixPackageSets has no Lix build of either, so that mix
  # is intentional (#561). nix-direnv has one and uses it (home/direnv.nix).
  nix.package = pkgs.lix;

  # Weekly GC via `nh clean all` instead of nix.gc: besides system and user
  # generations it also drops stale GC roots (`result` links, nix-direnv
  # profiles). Keeps the last 14 days as a rollback window. Runs as root, so
  # nh skips self-elevation. home-manager's programs.nh.clean is not used
  # because on Darwin it only runs `nh clean user`.
  launchd.daemons.nh-clean = {
    command = "${lib.getExe pkgs.nh} clean all --keep-since 14d";
    path = [ config.nix.package ];
    serviceConfig.RunAtLoad = false;
    serviceConfig.StartCalendarInterval = {
      Weekday = 0;
      Hour = 3;
      Minute = 15;
    };
  };
  nix.optimise = {
    automatic = true;
    interval = {
      Weekday = 0;
      Hour = 4;
      Minute = 15;
    };
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  # Flakes only: without this NIX_PATH still carries the root channels.
  nix.channel.enable = false;
  # The primary user is deliberately not in trusted-users. A trusted user can
  # set any daemon setting, including substituters and post-build-hook, which
  # amounts to root, and every process running as that user inherits it
  # (#560). What needed that trust is declared here instead: the binary cache
  # devenv's nixpkgs is built into.
  nix.settings.substituters = [ "https://devenv.cachix.org" ];
  nix.settings.trusted-public-keys = [
    "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
  ];

  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
  system.stateVersion = 5;
}
