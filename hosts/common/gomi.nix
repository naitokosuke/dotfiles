{
  config,
  lib,
  pkgs,
  ...
}:

let
  # /tmp is cleared on reboot, so a weekly job's output would be gone by the
  # time it is needed (issue #369)
  logFile = "${config.naitokosuke.homeDirectory}/Library/Logs/gomi-prune.log";
in
{
  launchd.user.agents.gomi-prune = {
    serviceConfig = {
      ProgramArguments = [
        (lib.getExe pkgs.gomi)
        "--prune=45d,orphans"
      ];
      StartCalendarInterval = [
        {
          Weekday = 0;
          Hour = 3;
        }
      ];
      StandardOutPath = logFile;
      StandardErrorPath = logFile;
    };
  };
}
