# Nix Configuration for macOS

Personal Nix configuration for macOS using [nix-darwin](https://github.com/LnL7/nix-darwin) and [home-manager](https://github.com/nix-community/home-manager).

An interactive, VS Code-flavoured walkthrough of this repository is published at
**[naitokosuke-dotfiles.void.app](https://naitokosuke-dotfiles.void.app/)** (source in [`docs/`](docs/)).

## Prerequisites

- macOS on Apple Silicon
- [Lix](https://lix.systems/) package manager
- Xcode Command Line Tools (required for Homebrew)

## Installation

1. Install Xcode Command Line Tools:
   ```bash
   xcode-select --install
   ```

2. Install Lix:
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.lix.systems/lix | sh -s -- install
   ```

3. Clone this repository:
   ```bash
   git clone https://github.com/naitokosuke/dotfiles.git
   cd dotfiles
   ```

4. Apply the configuration:
   ```bash
   nix run nix-darwin --extra-experimental-features "nix-command flakes" -- switch --flake .#Mac-big
   ```

## Configuration Structure

```
.
├── flake.nix          # Entry point: flake inputs and darwinConfigurations
├── nvfetcher.toml     # Version tracker for CLI tools not in nixpkgs (nvfetcher)
├── pkgs/              # Custom package derivations (ax, octorus, vite-plus, vize, …)
│   └── _sources/      # nvfetcher-generated pins (version + URL + hash) — never edit by hand
├── modules/
│   └── naitokosuke/   # Shared module: personal constants (username, email, …)
│                      #   exposed as `config.naitokosuke.*` to both nix-darwin and home-manager
├── hosts/             # System-level macOS settings (nix-darwin)
│   ├── common/        # Shared settings — Dock, Finder, keyboard, Homebrew,
│   │                  #   packages, Nix daemon, and home-manager wiring
│   ├── Mac-big/       # Mac mini host
│   └── Macbook-heavy/ # MacBook host (Touch ID for sudo)
├── home/              # User-level settings (home-manager), one module per program
│   ├── shell/         # Shell configurations (Nushell, Zsh)
│   ├── git.nix        # Git
│   ├── claude.nix     # Claude Code settings, rules, skills
│   ├── ghostty.nix    # Terminal
│   ├── starship.nix   # Prompt
│   └── …              # atuin, direnv, gh, gwq, mcp, nh, ssh, vscode, …
└── docs/              # Interactive walkthrough web app (Vite+ / void)
                       #   deployed to https://naitokosuke-dotfiles.void.app/
```

Each `default.nix` aggregates the modules in its directory — see them for the full list.

### CLI Packages

Managed via nixpkgs. See [`hosts/common/packages.nix`](hosts/common/packages.nix).

Tools not available in nixpkgs (e.g. [`ax`](https://github.com/yusukebe/ax),
[`vize`](https://github.com/ubugeeei-prod/vize), [`octorus`](https://github.com/ushironoko/octorus),
[`vite-plus`](https://github.com/voidzero-dev/vite-plus) (`vp`),
[`playwright-cli`](https://github.com/microsoft/playwright-cli))
are packaged in [`pkgs/`](pkgs/),
with versions and hashes tracked by [nvfetcher](https://github.com/berberman/nvfetcher) via
[`nvfetcher.toml`](nvfetcher.toml). A daily GitHub Actions workflow (08:00 JST) regenerates the pins and opens an update PR.

vite-plus is the one package with a second half: `vp` is only a launcher, and the JavaScript toolchain
it delegates to is built from [`pkgs/vite-plus-runtime/`](pkgs/vite-plus-runtime/) and installed
alongside it. The two must stay on the same version, so the derivation refuses to evaluate if the
lockfile and the nvfetcher pin disagree, and the nvfetcher workflow regenerates the lockfile as part
of the same PR. The approach follows [nix-vite-plus](https://github.com/ryoppippi/nix-vite-plus).

Once the official nixpkgs packaging of vite-plus ([NixOS/nixpkgs#533925](https://github.com/NixOS/nixpkgs/pull/533925))
lands, `pkgs/vite-plus.nix` will be replaced by `pkgs.vite-plus` (see the TODO in that file).

### GUI Apps

Managed via Homebrew Casks. See [`hosts/common/homebrew.nix`](hosts/common/homebrew.nix).

### Hosts

The flake builds one `darwinConfiguration` per host listed in [`flake.nix`](flake.nix):

| Host            | Machine     |
| --------------- | ----------- |
| `Mac-big`       | Mac mini    |
| `Macbook-heavy` | MacBook     |

## Customization

1. Update `hosts/common/packages.nix`: Add or remove CLI packages
2. Update `hosts/common/`: Add or modify system settings
3. Update `home/`: Add or modify user (home-manager) configurations
4. Update `modules/naitokosuke/`: Change personal constants (username, email, …)

## Usage

Apply configuration changes:
```bash
darwin-rebuild switch --flake .#Mac-big
```

Update flake inputs:
```bash
nix flake update
darwin-rebuild switch --flake .#Mac-big
```

Update nvfetcher-tracked tool versions (regenerates `pkgs/_sources/`):
```bash
nix run nixpkgs#nvfetcher -- -o pkgs/_sources
```

## VSCode Settings Sync

VSCode settings are automatically synchronized from the [vscode-settings](https://github.com/naitokosuke/vscode-settings) repository

- Settings and keybindings are managed through Home Manager
- Existing settings are automatically backed up with `.backup` extension
- JSONC keybindings are converted to JSON format automatically
- Changes to the settings repository are applied with `darwin-rebuild switch`

## Walkthrough Site (`docs/`)

[`docs/`](docs/) is a [Vite+](https://viteplus.dev/) / [void](https://void.app/) single-page app that renders this
repository as an interactive, VS Code-flavoured walkthrough. It reads the actual `*.nix` files, `nvfetcher.toml`, the
GitHub workflows, and this README at build time, so the published site always mirrors the real configuration.

```bash
cd docs
vp install   # install dependencies
vp dev       # local dev server
vp build     # production build
vp check     # format, lint, and type-check
```

It is deployed to <https://naitokosuke-dotfiles.void.app/> on every push to `main` by
[`.github/workflows/deploy-docs.yml`](.github/workflows/deploy-docs.yml), which needs a `VOID_TOKEN` repository
secret (`vp exec void auth token` in `docs/` copies the token to the clipboard). `vp run deploy` deploys by hand.
