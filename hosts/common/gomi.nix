{
  lib,
  pkgs,
  ...
}:

# No StandardOutPath / StandardErrorPath: gomi records each prune in its own
# log (~/.local/share/gomi/debug.log, see home/gomi.nix), so launchd's copy of
# stdout/stderr is discarded (issue #369).
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
    };
  };
}
