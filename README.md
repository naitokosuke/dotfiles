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
   sudo nix run nix-darwin --extra-experimental-features "nix-command flakes" -- switch --flake .#Mac-big
   ```

## First-Time Setup on a New Machine

Activation builds everything this repository declares, and nothing below. Until these steps are
done the machine looks healthy: the very first `git commit` is what fails, because
[`home/git.nix`](home/git.nix) signs every commit and tag with `~/.ssh/id_ed25519.pub` and nothing
here creates that key.

Run them after the Installation switch above — `gh`, `ghq` and `playwright-cli` come from the
configuration — and in this order.

* Generate the key pair that [`home/ssh.nix`](home/ssh.nix) uses as the GitHub identity and
  `home/git.nix` signs with. Keep the default path (`~/.ssh/id_ed25519`); `UseKeychain` stores the
  passphrase in the macOS Keychain on first use.
  ```bash
  ssh-keygen -t ed25519 -C "kosuke.naito.engineer@gmail.com"
  ```

* Log in to GitHub and register the public key twice — as an authentication key to push, and as a
  signing key so GitHub reports the signatures as verified rather than the commits as unsigned.
  Adding keys needs scopes beyond the default login.
  ```bash
  gh auth login
  gh auth refresh -h github.com -s admin:public_key -s admin:ssh_signing_key
  gh ssh-key add ~/.ssh/id_ed25519.pub --type authentication --title "$(hostname -s)"
  gh ssh-key add ~/.ssh/id_ed25519.pub --type signing --title "$(hostname -s)"
  ```

* Clone the repositories [`home/claude.nix`](home/claude.nix) links into `~/.claude`. Those are
  out-of-store symlinks into working trees under the ghq root, so activation succeeds either way
  and the links simply dangle until the trees exist.
  ```bash
  ghq get naitokosuke/rule-rule-rule
  ghq get naitokosuke/skill-skill-skill
  ```

* Install the Playwright browsers. They are runtime-managed on purpose, so no closure contains
  them and a fresh machine has none — see [`home/playwright.nix`](home/playwright.nix) for where
  they land.
  ```bash
  playwright-cli install-browser chromium
  ```

### Secrets

Nothing in this repository is encrypted and no secrets framework (`sops-nix`, `agenix`) is in the
flake. That is a decision rather than an omission: the SSH key above and the Keychain cover
everything this setup needs, and machine-local or private SSH host definitions are deliberately
kept out of the repository — `home/ssh.nix` includes them from `~/.ssh/config.d/` instead.

A framework would not remove the manual step either. An age key derived from the SSH key inherits
the ordering problem above: the key that decrypts the secrets is the same key the bootstrap has to
create by hand first. Worth revisiting when there is a secret that actually wants to live in here.

## Configuration Structure

```
.
├── flake.nix          # Entry point: flake inputs and darwinConfigurations
├── nvfetcher.toml     # Version tracker for CLI tools not in nixpkgs (nvfetcher)
├── pkgs/              # Custom package derivations (frog, gh-sub-issue, gwq, playwright-cli, vite-plus)
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
│   ├── claude-*       # Claude Code deletion guard hook and Seatbelt sandbox
│   └── …              # atuin, direnv, gh, gh-dash, gomi, gwq, mcp, nh, ssh, vite-plus, vscode, zoxide
└── docs/              # Interactive walkthrough web app (Vite+ / void)
                       #   deployed to https://naitokosuke-dotfiles.void.app/
```

Each `default.nix` aggregates the modules in its directory — see them for the full list.

### CLI Packages

Managed via nixpkgs. See [`hosts/common/packages.nix`](hosts/common/packages.nix).

Tools not available in nixpkgs ([`frog`](https://github.com/wevm/frog),
[`gh-sub-issue`](https://github.com/yahsan2/gh-sub-issue), [`gwq`](https://github.com/d-kuro/gwq),
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
sudo darwin-rebuild switch --flake .#Mac-big
```

`sudo darwin-rebuild-nom switch --flake .#Mac-big` does the same with nix-output-monitor progress, and
`nh darwin switch` picks the host from the hostname and shows a closure diff before activating.

Update flake inputs:
```bash
nix flake update
sudo darwin-rebuild switch --flake .#Mac-big
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
- Changes to the settings repository are applied with `nix flake update vscode-settings` and a rebuild

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
