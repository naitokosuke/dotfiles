# Blocks shell commands that delete files irreversibly; see ./rm-guard.ts.
# Instructions in CLAUDE.md or skills can be ignored; a hook runs on every
# Bash call. It blocks rm, unlink, rmdir, shred, `find -delete` / `-exec rm`
# and `git clean` (not `git rm`, which history undoes), and the reason it
# returns tells the agent to use gomi instead. The Seatbelt sandbox in
# ../claude-sandbox.nix covers what slips past (e.g. `fs.rmSync` inside a
# script), but cannot tell deletion apart from the rename gomi relies on, so
# forcing gomi has to happen here.
{
  lib,
  pkgs,
  ...
}:

let
  ## The script
  # rm-guard.ts is one TypeScript file run by Bun with the standard library
  # only, so there is no lockfile or hash to keep in step (#599). It parses
  # the command with `shfmt --to-json` and walks every call in the AST, so
  # subshells, pipelines and `&&` chains are covered; wrappers such as sudo,
  # env, xargs and `find -exec` are peeled off, and `sh -c` / `eval` bodies
  # are parsed again. Anything it cannot check is blocked. A block is returned
  # as `permissionDecision: "deny"`, and every unexpected failure is turned
  # into a deny too, because any other non-zero exit would let the command
  # run. `bun test` covers the allow and deny cases; `nix flake check` runs it.
  rm-guard = pkgs.writeShellScript "claude-rm-guard" ''
    SHFMT=${lib.getExe pkgs.shfmt} exec ${lib.getExe pkgs.bun} ${./rm-guard.ts}
  '';
in
{
  ## Registration
  # Registered for the Bash and Monitor tools; home-manager merges it with the
  # hooks ../claude.nix and ../adrafinil.nix declare.
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
