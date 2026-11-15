# Blocks shell commands that delete files irreversibly, and tells the agent to
# use `gomi` instead; see ./rm-guard.ts.
# The Seatbelt sandbox in ../claude-sandbox.nix covers what slips past (e.g.
# `fs.rmSync` inside a script).
{
  lib,
  pkgs,
  ...
}:

let
  ## The wrapper
  # Bun runs the script, with the store path of shfmt.
  rm-guard = pkgs.writeShellScript "claude-rm-guard" ''
    SHFMT=${lib.getExe pkgs.shfmt} exec ${lib.getExe pkgs.bun} ${./rm-guard.ts}
  '';
in
{
  ## Registration
  # For Bash and Monitor calls. home-manager merges it with the hook in
  # home/claude.nix.
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
