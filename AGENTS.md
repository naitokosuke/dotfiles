# AGENTS.md

## Friction logging (frog)

- Run `frog list` first to see what is already known
- Log papercuts and friction (tooling, docs, APIs, tests, conventions) as you hit them with `frog log`
- Do not add global, system, or internal friction
- `frog` is installed system-wide via Nix (`pkgs/frog.nix`); never install it ad hoc
- Entries under `.agents/friction-log/` are intentionally untracked in this repository; file an issue explicitly with `frog publish` when an entry deserves an owner

## Tooling

- Do not use `jq`. The repository is Nix plus thin bash: read JSON with `builtins.fromJSON` (`nix eval`), and write anything larger than a few lines as a Nix function or as a TypeScript file run by Bun
- `nix flake check` fails when `jq` appears anywhere outside this file
