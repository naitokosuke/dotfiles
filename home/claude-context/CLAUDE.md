# Agent Guidelines

YAGNI, KISS, DRY. Prefer simplicity over pathological correctness.

## CLI Tools

- `fd` instead of `find`
- `rg` (ripgrep) instead of `grep`
- `sd` instead of `sed`
- `gomi` instead of `rm` (permanent deletion is blocked; `gomi --restore` brings files back)
