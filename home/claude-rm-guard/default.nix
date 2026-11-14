# Blocks shell commands that delete files irreversibly; see ./rm-guard.ts.
# The Seatbelt sandbox in ../claude-sandbox.nix covers what slips past (e.g.
# `fs.rmSync` inside a script).
{
  lib,
  pkgs,
  ...
}:

let
  rm-guard = pkgs.writeShellScript "claude-rm-guard" ''
    SHFMT=${lib.getExe pkgs.shfmt} exec ${lib.getExe pkgs.bun} ${./rm-guard.ts}
  '';
in
{
  programs.claude-code.settings.hooks.PreToolUse = [
    {
      matcher = "Bash|Monitor";
      hooks = [
        {
          type = "command";
          command = "${rm-guard}";
          timeout = 10;
        }
      ];
    }
  ];
}
