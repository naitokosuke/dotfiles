{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

{
  # Disable nix-darwin's /etc/zshrc management.
  # Zsh configuration is handled entirely by home-manager.
  # Nushell is the primary interactive shell; Zsh serves as login shell
  # for IDE integrations and SSH sessions.
  programs.zsh.enable = false;

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

  nix.settings.experimental-features = "nix-command flakes";
  nix.settings.trusted-users = [
    "root"
    config.naitokosuke.username
  ];

  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
  system.stateVersion = 5;
}
