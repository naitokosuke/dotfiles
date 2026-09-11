import type { Walkthrough } from "./types.ts";

interface Explanation {
  readonly about: string;
  readonly tags?: readonly string[];
  readonly walkthrough?: Walkthrough;
}

export const explanations: Readonly<Record<string, Explanation>> = {
  "README.md": {
    about: "Top-level README. Prerequisites, install steps, directory layout.",
    tags: ["docs", "entry"],
    walkthrough: {
      intro:
        "The README is the single page a newcomer should be able to read end-to-end and reproduce this machine. It states the OS prerequisites (Apple Silicon + Lix), the bootstrap command, the directory split between `hosts/` and `home/`, and the everyday `darwin-rebuild` workflow.",
      sections: [
        {
          title: "Prerequisites",
          prose:
            "Apple Silicon and Lix only — no Intel support and no upstream `nix` installer. Xcode CLT is required because the Homebrew layer depends on it.",
          lines: [8, 12],
        },
        {
          title: "Bootstrapping",
          prose:
            "Install Lix, clone, then run `nix-darwin switch --flake .#<host>` once. After that, the system is reproducible from this directory.",
          lines: [14, 35],
        },
      ],
    },
  },

  "flake.nix": {
    about: "Entry point of the Nix flake. Inputs and darwinConfigurations.",
    tags: ["flake", "entry"],
    walkthrough: {
      intro:
        "`flake.nix` is the single source of truth for the whole environment. It pins every upstream input (nixpkgs, nix-darwin, home-manager, nix-homebrew, plus a few personal forks), then assembles `darwinConfigurations` for each Mac. `darwin-rebuild` resolves everything from this file alone — given the same `flake.lock`, the machine is bit-for-bit reproducible.",
      sections: [
        {
          title: "Inputs",
          prose:
            "Every upstream is pinned and `follows = nixpkgs` so the world ships one pkgs set. `vscode-settings` and a few non-flake inputs (`homebrew-cask`, `skill-skill-skill`, `nu-scripts`) are locked snapshots read at eval time. The personal `*-nix` flakes that used to live here (`vize`, `octorus`, `vp`) have all moved into `./pkgs` under nvfetcher tracking.",
          lines: [4, 49],
        },
        {
          title: "mkDarwinConfig",
          prose:
            "A small helper that builds one `darwinSystem` per host. It pins `aarch64-darwin` and Nixpkgs config (`allowUnfree` plus overlays: the custom `./pkgs` set tracked by nvfetcher, and `nushell` / `direnv` overrides that disable broken sandbox tests) inside an inline module — a `{ config, ... }:` function so `system.primaryUser` derives from `config.naitokosuke.username` rather than a hardcoded literal. It loads `./modules/naitokosuke` for those constants, then stitches `hosts/common`, `hosts/<hostName>`, and `home-manager` together.",
          lines: [72, 118],
        },
        {
          title: "Per-host configurations",
          prose:
            "`darwinConfigurations` is built by mapping the `hosts` list (defined just above) through `mkDarwinConfig` with `nixpkgs.lib.genAttrs`. Adding a new Mac is a one-line append to that list — plus a `hosts/<host>/default.nix` for the diff — with no per-host `darwinConfigurations` attribute to hand-write.",
          lines: [121, 121],
        },
        {
          title: "Custom packages output",
          prose:
            "`packages.<system>` exposes the same `./pkgs` set that the overlay injects, so `nix build .#ax` works standalone — handy for testing a derivation without evaluating a whole darwin configuration.",
          lines: [123, 123],
        },
      ],
    },
  },

  "nvfetcher.toml": {
    about: "nvfetcher config — tracks upstream releases of tools not in nixpkgs.",
    tags: ["packages", "automation"],
    walkthrough: {
      intro:
        "The version tracker for CLI tools that nixpkgs doesn't ship. Each entry names an upstream to watch and an asset to fetch; running `nix run nixpkgs#nvfetcher -- -o pkgs/_sources` resolves the latest release and regenerates `pkgs/_sources/generated.nix` with pinned URLs and hashes. No more hand-editing versions or copy-pasting sha256 values.",
      sections: [
        {
          title: "The ax entry",
          prose:
            "`src.github` watches `yusukebe/ax` releases; `fetch.url` downloads the `ax-darwin-arm64` binary for that tag (`$ver` is substituted). The entry is named after the exact asset it pins, so adding another platform later is a new entry, not a rewrite.",
          lines: [4, 6],
        },
        {
          title: "The vize, octorus, and vite-plus entries",
          prose:
            '`vize`, `octorus`, and `vite-plus` (`vp`) follow the same pattern with tar.gz assets — they replaced the standalone `vize-nix` / `octorus-nix` / `vp-nix` flake repos. One wrinkle: the octorus asset name embeds the version without the tag\'s `v` prefix, so `src.prefix = "v"` strips it at the tracker level and the URL re-adds it where needed.',
          lines: [8, 21],
        },
      ],
    },
  },

  "pkgs/_sources/generated.nix": {
    about: "nvfetcher-generated pins — version, URL, and sha256 per tracked tool.",
    tags: ["packages", "generated"],
    walkthrough: {
      intro:
        "Machine-generated by nvfetcher — never edited by hand. It's committed on purpose: Nix evaluation is pure, so the pinned hash must exist in-tree, and the diff of this file in each update PR *is* the reviewable version bump. Think of it as `flake.lock` for tools that live outside the flake ecosystem.",
    },
  },

  "pkgs/default.nix": {
    about: "Entry point of the custom package set — wires _sources into derivations.",
    tags: ["packages", "index"],
    walkthrough: {
      intro:
        "The index of the custom package set. It `callPackage`s the colocated `_sources/generated.nix` to materialise the pins, then hands them to each derivation. The resulting attrset is consumed twice: injected into `pkgs` via an overlay in `flake.nix`, and exposed as the flake's `packages` output for standalone `nix build .#<name>`.",
    },
  },

  "pkgs/ax.nix": {
    about: "ax (the AI-era curl) — installs the prebuilt darwin-arm64 release binary.",
    tags: ["packages", "cli"],
    walkthrough: {
      intro:
        "`ax` is a TypeScript CLI distributed as Bun-compiled binaries, so building from source under Nix would be painful for no gain. Instead this derivation installs the prebuilt `ax-darwin-arm64` asset that nvfetcher pinned — the version and hash both come from `sources`, so the file itself never changes on a version bump.",
      sections: [
        {
          title: "Fetch and install",
          prose:
            '`stdenvNoCC` because nothing is compiled. The `src` is a single executable (not an archive), so `dontUnpack` skips the unpack phase and `install -Dm755` places it as `$out/bin/ax`. `lib.removePrefix "v"` turns the upstream tag into a tidy Nix version.',
          lines: [7, 18],
        },
        {
          title: "Metadata",
          prose:
            "`sourceProvenance = binaryNativeCode` honestly marks this as a prebuilt binary, and `platforms` is pinned to `aarch64-darwin` — the only asset we track, and the only system this flake targets.",
          lines: [20, 29],
        },
      ],
    },
  },

  "pkgs/vize.nix": {
    about: "vize (Vue.js toolchain in Rust) — installs the prebuilt darwin-arm64 tarball.",
    tags: ["packages", "cli"],
    walkthrough: {
      intro:
        "Same story as `ax`: upstream ships prebuilt binaries, so the derivation just installs the `vize-aarch64-apple-darwin.tar.gz` asset that nvfetcher pinned. This replaced the standalone `vize-nix` flake repo — one less repository and update pipeline to maintain.",
      sections: [
        {
          title: "Fetch and install",
          prose:
            'The tarball is flat — no top-level directory, just the `vize` binary — so `sourceRoot = "."` keeps the unpacker in place and `install -Dm755` does the rest.',
          lines: [8, 20],
        },
        {
          title: "Version self-check",
          prose:
            "`versionCheckHook` runs `vize --version` after install and fails the build if the output doesn't match the derivation version — a cheap guard against upstream renaming assets or shipping a mislabeled binary.",
          lines: [22, 23],
        },
      ],
    },
  },

  "pkgs/octorus.nix": {
    about: "octorus (AI-powered PR review tool) — installs the prebuilt darwin-arm64 tarball.",
    tags: ["packages", "cli"],
    walkthrough: {
      intro:
        "This replaced the standalone `octorus-nix` flake repo — and simplified it: octorus-nix compiled the Rust workspace from source on every version bump, but upstream publishes prebuilt binaries, so this derivation just unpacks the pinned tarball. No more rustc runs during `darwin-rebuild switch`.",
      sections: [
        {
          title: "Fetch and install",
          prose:
            "The tarball unpacks into a versioned directory containing the `or` binary (yes, the CLI is called `or`, not `octorus` — hence `mainProgram`). stdenv auto-detects the single top-level directory, so no `sourceRoot` juggling is needed.",
          lines: [7, 16],
        },
      ],
    },
  },

  "pkgs/vite-plus.nix": {
    about: "vite-plus (vp) — installs the official prebuilt darwin-arm64 release binary.",
    tags: ["packages", "cli"],
    walkthrough: {
      intro:
        "The Nix equivalent of upstream's `curl | bash` installer: it installs the same prebuilt `vp-aarch64-apple-darwin.tar.gz` that the official script downloads, pinned by nvfetcher, plus the `vpr` / `vpx` aliases the installer would create. This replaced the standalone `vp-nix` flake repo. `vp` manages its own JS toolchain at runtime (`vp install` per project), so the binary and its aliases are all Nix needs to provide. The TODO on top marks the exit plan: once nixpkgs ships vite-plus (NixOS/nixpkgs#533925), this file gives way to `pkgs.vite-plus`.",
      sections: [
        {
          title: "Fetch and install",
          prose:
            'Same shape as `vize`: the tarball is flat — just the `vp` binary — so `sourceRoot = "."` keeps the unpacker in place and `install -Dm755` drops it at `$out/bin/vp`.',
          lines: [9, 19],
        },
        {
          title: "The vpr/vpx aliases",
          prose:
            "The official installer runs `vp env setup`, which symlinks `vpr` and `vpx` next to `vp` — a multi-call binary dispatching on `argv[0]` (`vpr` → `vp run`, `vpx` → `vp dlx`). The derivation reproduces exactly those two links. The `node`/`npm`/`npx`/`corepack` shims the same step creates are deliberately omitted: they belong to the opt-out-able Node version manager and would shadow Nix-managed Node.",
          lines: [20, 26],
        },
        {
          title: "Metadata",
          prose:
            '`sourceProvenance = binaryNativeCode` marks the prebuilt binary honestly, `mainProgram = "vp"` names the CLI, and `platforms` pins `aarch64-darwin` — the one asset this entry tracks.',
          lines: [30, 38],
        },
      ],
    },
  },

  ".github/workflows/nvfetcher.yml": {
    about: "Daily CI — reruns nvfetcher and opens an update PR when pins change.",
    tags: ["ci", "automation"],
    walkthrough: {
      intro:
        "The automation half of the nvfetcher story. Every morning at 08:00 JST (or on manual dispatch) CI reruns nvfetcher; if any tracked tool released a new version, the regenerated `pkgs/_sources/` lands in an auto-created pull request instead of anyone remembering to bump versions. Requires the repo setting that lets Actions create PRs.",
      sections: [
        {
          title: "Running nvfetcher",
          prose:
            "A throwaway keyfile passes `GITHUB_TOKEN` to nvfetcher so release lookups aren't rate-limited, then `nix run nixpkgs#nvfetcher -- -o pkgs/_sources` regenerates the pins — the same command used locally, so CI and laptop can never disagree.",
          lines: [21, 24],
        },
        {
          title: "The update PR",
          prose:
            "`peter-evans/create-pull-request` commits only `pkgs/_sources/` to a fixed `nvfetcher-update` branch — repeated runs update the same PR rather than piling up new ones, and the branch deletes itself on merge.",
          lines: [26, 35],
        },
      ],
    },
  },

  ".github/workflows/deploy-docs.yml": {
    about: "CI — redeploys this walkthrough site to void on every push to main.",
    tags: ["ci", "web"],
    walkthrough: {
      intro:
        "The site reads the repository's real config files at build time, so it's only as current as its last deploy. This workflow redeploys it to void on every push to `main` (or on manual dispatch), so the published walkthrough never lags behind the configuration it describes.",
      sections: [
        {
          title: "Triggers and concurrency",
          prose:
            "There's no `paths` filter: the build globs `*.nix`, the README, and the workflows from across the repository, so almost any change to `main` alters what the site renders. Deploys share one concurrency group without cancelling, so an upload is never interrupted midway, and since only the newest pending run is kept, a burst of merges still ends on the latest `main`.",
          lines: [3, 18],
        },
        {
          title: "Deploy",
          prose:
            "`voidzero-dev/setup-vp` installs Vite+ and runs `vp install` in `docs/`, then `vp run deploy` runs the same `void deploy` used locally. `VOID_TOKEN` is a repository secret holding the token `void auth token` copies to the clipboard. The local project link in `.void/project.json` is gitignored, so `VOID_PROJECT` names the project explicitly — without it, `void deploy` would fail in CI rather than prompt.",
          lines: [26, 40],
        },
      ],
    },
  },

  "modules/naitokosuke/default.nix": {
    about: "Typed personal-constants module — username, full name, email, home directory.",
    tags: ["module", "config"],
    walkthrough: {
      intro:
        "A small NixOS-module-style namespace that centralizes the personal literals that used to be scattered across the tree. It declares typed `naitokosuke.{username,fullName,email,homeDirectory}` options and sets their defaults, so every other module reads `config.naitokosuke.*` instead of hardcoding `naitokosuke`. It's loaded into both nix-darwin (via the flake `modules` list) and home-manager (via `home-manager.sharedModules`), so both trees resolve the same values — and a host can override any of them in one place.",
      sections: [
        {
          title: "Typed options",
          prose:
            "Each constant is an `mkOption` with `type = types.str` and a description, so the values are self-documenting and type-checked rather than bare strings copied around the repo.",
          lines: [13, 30],
        },
        {
          title: "Defaults",
          prose:
            "`config.naitokosuke` sets the defaults for this user. Because they're module options, a per-host module can override any field without touching the call sites that consume them.",
          lines: [32, 37],
        },
      ],
    },
  },

  "hosts/common/default.nix": {
    about: "Aggregates the nix-darwin modules shared across every Mac.",
    tags: ["darwin", "index"],
    walkthrough: {
      intro:
        "This is the index for the *system* layer — every module that should apply to every Mac. The whole file is just an `imports` list; the real configuration lives in the sibling files. Adding a new system-wide concern means dropping a `.nix` here and importing it.",
    },
  },

  "hosts/common/dock.nix": {
    about: "macOS Dock — autohide, tile sizes, suppressed recents.",
    tags: ["macos", "ui"],
    walkthrough: {
      intro:
        "Locks the Dock to a consistent, minimal layout. The Dock auto-hides, suppresses recent apps so its width stays predictable, and uses a small base tile with hover magnification.",
      sections: [
        {
          title: "Auto-hide and suppress recents",
          prose:
            "`autohide` reclaims the bottom of the screen by default; the Dock only appears when the cursor hits the edge. `show-recents = false` stops the Dock from growing unpredictably as you switch projects.",
          lines: [4, 6],
        },
        {
          title: "Sizing and animation",
          prose:
            "Tiles render at 50px and magnify to 64px on hover — enough feedback without being noisy. `mineffect = scale` is sharper than the genie default, and `launchanim = false` removes the bouncing icon during app launch.",
          lines: [7, 12],
        },
      ],
    },
  },

  "hosts/common/finder.nix": {
    about: "Finder — show extensions, hidden files, column view, status bar.",
    tags: ["macos", "ui"],
    walkthrough: {
      intro:
        "Tuned for power-user Finder use. Extensions are always shown, hidden files are visible, the desktop is wiped clean of icons, and Finder defaults to Column view with the path and status bars on.",
    },
  },

  "hosts/common/gomi.nix": {
    about: "Launchd agent that prunes Trash items older than 45 days via gomi.",
    tags: ["launchd", "automation"],
    walkthrough: {
      intro:
        "`gomi` is a safer `rm` that moves files to a Trash directory. This module installs a user `launchd` agent that runs `gomi --prune=45d,orphans` on a schedule, so the Trash doesn't accumulate forever.",
      sections: [
        {
          title: "The launchd agent",
          prose:
            "`ProgramArguments` resolves `gomi` from the Nix store via `lib.getExe` — no $PATH dependency. `StartCalendarInterval` runs the prune daily; the agent is owned by the user so it doesn't need root.",
        },
      ],
    },
  },

  "hosts/common/home-manager.nix": {
    about: "Bridge from nix-darwin to home-manager.",
    tags: ["bridge", "home-manager"],
    walkthrough: {
      intro:
        "Wires `home-manager` into nix-darwin so the user-side configuration ships alongside the system. `useGlobalPkgs` and `useUserPackages` keep both layers on the same nixpkgs instance, `sharedModules` injects the `modules/naitokosuke` personal-constants module into the home-manager tree, and `home/` (its `default.nix`) is imported as the user's home configuration.",
    },
  },

  "hosts/common/homebrew.nix": {
    about: "Declarative Homebrew via nix-homebrew. GUI apps as Casks.",
    tags: ["homebrew", "gui"],
    walkthrough: {
      intro:
        "macOS GUI apps don't fit Nix's model cleanly, so we keep a thin Homebrew layer for them. `nix-homebrew` provides the bridge — Homebrew itself, the Cask tap, and the desired cask set are all declared, then materialised on every `darwin-rebuild`.",
      sections: [
        {
          title: "nix-homebrew setup",
          prose:
            "`nix-homebrew` installs and pins the Homebrew binary itself via Nix. `taps` pulls every tap from a flake input, so even Homebrew's tap repos are pinned. `mutableTaps = false` makes them read-only — `brew tap` is disabled, and a new tap has to arrive as a flake input.",
          lines: [8, 21],
        },
        {
          title: "Taps and activation policy",
          prose:
            'The Brewfile mirrors the pinned tap list so `brew bundle` cleanup does not untap them. `HOMEBREW_NO_INSTALL_FROM_API` forces cask definitions to come from those pinned taps rather than Homebrew\'s API, and `cleanup = "uninstall"` converges the machine onto exactly the cask list below — new versions arrive via `nix flake update`.',
          lines: [23, 42],
        },
        {
          title: "Casks",
          prose:
            "Everything in `casks` is materialised on `darwin-rebuild`. `productdevbook/tap/portkiller` and `stablyai/orca/orca` show how third-party taps slot in.",
          lines: [44, 63],
        },
      ],
    },
  },

  "hosts/common/key_repeat.nix": {
    about: "Fastest macOS key-repeat tuning (KeyRepeat=1, InitialKeyRepeat=20).",
    tags: ["macos", "keyboard"],
    walkthrough: {
      intro:
        "macOS's default key-repeat is glacial for vim/Nushell muscle memory. `KeyRepeat = 1` is the fastest tick the OS exposes, and `InitialKeyRepeat = 20` (≈ 200 ms) cuts the dead-time before repeat kicks in.",
    },
  },

  "hosts/common/keyboard.nix": {
    about: "Disables Ctrl+Space / Ctrl+Option+Space input-source switching.",
    tags: ["macos", "keyboard"],
    walkthrough: {
      intro:
        "The macOS input-source toggles `Ctrl+Space` and `Ctrl+Option+Space` collide with editor / shell keybinds. Disabling them via `symbolichotkeys` frees those chords for vim, Emacs-style readline, and Nushell.",
    },
  },

  "hosts/common/menubar.nix": {
    about: "Hides the macOS menu bar permanently.",
    tags: ["macos", "ui"],
    walkthrough: {
      intro:
        "`_HIHideMenuBar = true` hides the menu bar permanently — it slides in only when the cursor hits the top edge. Combined with the auto-hidden Dock, every pixel of vertical space is reclaimed for the editor or terminal.",
    },
  },

  "hosts/common/nix.nix": {
    about: "Nix runtime — uses Lix, enables flakes, schedules GC.",
    tags: ["nix", "infra"],
    walkthrough: {
      intro:
        "Configures the Nix daemon itself. Lix replaces upstream Nix, `experimental-features` turns on `nix-command` and `flakes`, and zsh's `/etc` management is delegated to home-manager so Nushell stays the primary interactive shell.",
      sections: [
        {
          title: "Hand zsh to home-manager",
          prose:
            "`nix-darwin` normally rewrites `/etc/zshrc`; disabling that lets home-manager own every dotfile end-to-end. Nushell is the interactive shell in Ghostty, so zsh stays minimal — just the login shell for IDEs / SSH.",
        },
        {
          title: "Lix + flakes",
          prose:
            '`nix.package = pkgs.lix` opts into the Lix fork (CppNix maintenance line). `experimental-features = "nix-command flakes"` turns on flakes globally so every shell can do `nix run`, `nix build`, etc., without `--extra-experimental-features` flags.',
        },
      ],
    },
  },

  "hosts/common/packages.nix": {
    about: "System-wide CLI packages declared in environment.systemPackages.",
    tags: ["cli", "packages"],
    walkthrough: {
      intro:
        "The system CLI toolbelt. Everything here is on `$PATH` for every user and login shell. The only derivation defined inline is `darwin-rebuild-nom` (pipes `darwin-rebuild` through `nix-output-monitor`); the rest come from nixpkgs, from the nvfetcher-tracked overlay in `./pkgs` (`ax`, `frog`, `gwq`, `octorus`, `vite-plus`, `vize`, …), or from a flake input.",
      sections: [
        {
          title: "darwin-rebuild-nom wrapper",
          prose:
            "`darwin-rebuild` doesn't accept `--log-format`, so we wrap it in a shell script that pipes stderr through `nix-output-monitor`. The result is the same rebuild command but with the richer progress UI Nix-flavoured CIs use.",
          lines: [7, 18],
        },
        {
          title: "The CLI toolbelt",
          prose:
            "Daily drivers: `gh`, `ghq`, `git`, `fd`, `fzf`, `ripgrep`, `sd`, `bun`, `pnpm`, `nodejs_24`. Language toolchains that should be available outside any project shell: `rustup`, `uv`, and `idris2`. Nix workflow tools: `nixd`, `devenv`, `nix-output-monitor`, plus the locally-built `darwin-rebuild-nom`. `ax`, `frog`, `gwq`, `octorus`, `playwright-cli`, `vite-plus` (`vp`), and `vize` come from the `./pkgs` overlay; only `herdr` is still wired in via a flake input.",
          lines: [20, 55],
        },
      ],
    },
  },

  "hosts/common/screen_capture.nix": {
    about: "Pins screenshot output to ~/Pictures/screenshots.",
    tags: ["macos"],
    walkthrough: {
      intro:
        "Screenshots default to the Desktop on macOS, which mixes them with everything else. Pinning them under `~/Pictures/screenshots` makes them easy to find and easy to ignore in `.gitignore`s.",
    },
  },

  "hosts/common/scroll.nix": {
    about: "Swipe scroll direction and scrollbar visibility mode.",
    tags: ["macos"],
    walkthrough: {
      intro:
        "Two small ergonomics toggles. `swipescrolldirection = true` keeps macOS's natural direction (drag content, not viewport). `AppleShowScrollBars = \"WhenScrolling\"` shows the scrollbar only during active scroll so it doesn't pin a column of pixels.",
    },
  },

  "hosts/Mac-big/default.nix": {
    about: "Mac mini (Mac-big) host overrides — currently empty.",
    tags: ["host"],
    walkthrough: {
      intro:
        "Per-host module for the Mac mini. Currently a placeholder — every behaviour the Mac mini needs comes from `hosts/common`. The file still exists so the flake's `mkDarwinConfig` can import `hosts/Mac-big` uniformly.",
    },
  },

  "hosts/Macbook-heavy/default.nix": {
    about: "MacBook Air overrides. Enables Touch ID for sudo.",
    tags: ["host"],
    walkthrough: {
      intro:
        "Only the MacBook has Touch ID, so the sudo PAM integration lives here rather than in `hosts/common`. `security.pam.services.sudo_local.touchIdAuth = true` lets `sudo` accept a fingerprint when a session is interactive on the laptop's built-in sensor.",
    },
  },

  "home/default.nix": {
    about: "Root of the user-side configuration — loads every tool module.",
    tags: ["home-manager", "index"],
    walkthrough: {
      intro:
        "The entry point for the *user* layer. It imports every per-tool module (atuin, direnv, gh, git, starship, vscode, …) and sets the basic `home` identity. Adding a new tool means writing a sibling `.nix` and importing it here.",
      sections: [
        {
          title: "Tool modules",
          prose:
            "Each tool gets its own file directly under `home/`. Composing them as a flat list keeps every concern shallow — opening `git.nix` shows the full git story, opening `claude.nix` shows the full Claude Code story.",
          lines: [8, 23],
        },
        {
          title: "Identity",
          prose:
            "`home.username` and `home.homeDirectory` are derived from `config.naitokosuke.*` — the typed personal-constants module — instead of being hardcoded, with `lib.mkForce` so the home path always wins over inferences. `home.stateVersion` is pinned at the version this config was first written for — never bump casually.",
          lines: [25, 28],
        },
      ],
    },
  },

  "home/atuin.nix": {
    about: "atuin (synced fuzzy shell history) with Zsh + Nushell integration.",
    tags: ["shell", "history"],
    walkthrough: {
      intro:
        "atuin replaces the shell's built-in history with a synced, fuzzy-searchable SQLite store. Both Zsh and Nushell hook into it, search mode is fuzzy, and the scope is global so the same history surfaces no matter which directory the search starts from.",
    },
  },

  "home/claude.nix": {
    about: "Claude Code module — writable configs, settings.json, hooks, permissions.",
    tags: ["ai", "claude"],
    walkthrough: {
      intro:
        "Claude Code expects to mutate its own configuration files (last-used model, recent projects, etc.), which conflicts with Nix's read-only store. This module solves it with a `mkWritableConfig` helper that *copies* files out of the store on activation rather than symlinking — so Claude Code can write back without touching `/nix/store`.",
      sections: [
        {
          title: "mkWritableConfig helper",
          prose:
            "The helper takes `{ dir, filename, content }` and produces a `home.activation` snippet. On activation, it removes any leftover store-symlink at the target path, then copies the desired content only if the file doesn't already exist — preserving any runtime changes the user has accumulated.",
        },
        {
          title: "settings.json and permissions",
          prose:
            "`settings.json` declares the global Claude Code preferences. The `permissions.deny` list keeps Claude from running anything destructive without an explicit prompt — see the `permissions.deny` commit history for the rationale on each rule.",
        },
      ],
    },
  },

  "home/direnv.nix": {
    about: "direnv + nix-direnv with a CGO_ENABLED-forced patched build.",
    tags: ["dev-env"],
    walkthrough: {
      intro:
        "`direnv` + `nix-direnv` is how per-project shells materialise — drop a `.envrc` into a project, run `direnv allow`, and the right `nix shell` or `devenv` env loads on `cd`. The package itself is overridden with `CGO_ENABLED = 1` to dodge a current nixpkgs check-phase hang on Darwin.",
    },
  },

  "home/gh.nix": {
    about: "GitHub CLI config plus the gh-sub-issue extension built via buildGoModule.",
    tags: ["github", "cli"],
    walkthrough: {
      intro:
        "`gh` is the GitHub CLI; this module configures it and ships the `gh-sub-issue` extension. Because the extension isn't in nixpkgs, it's built locally with `buildGoModule` (same pattern as `gwq`) — version-pinned via `rev` and content-pinned via `hash` / `vendorHash`.",
    },
  },

  "home/ghostty.nix": {
    about: "Ghostty terminal — Nushell shell, Catppuccin Mocha theme.",
    tags: ["terminal"],
    walkthrough: {
      intro:
        "Ghostty is the primary terminal. The actual binary comes from Homebrew Cask (`package = null` disables the Nix-side install to avoid double-installing), while the config — `command`, theme, fonts, padding — is fully declared here.",
    },
  },

  "home/git.nix": {
    about: "Global git config — ignores, aliases, delta diffs, commit signing.",
    tags: ["git"],
    walkthrough: {
      intro:
        "The user-global `~/.gitconfig`, declarative. Sets ignore patterns that cover `.DS_Store`, editor scratch files, and project-local secrets; configures `delta` as the diff pager for syntax-highlighted reviews; and enables commit signing so every commit ships verified.",
    },
  },

  "home/gwq.nix": {
    about: "gwq (worktree-flavoured ghq) configured via xdg.configFile-generated TOML.",
    tags: ["git", "workflow"],
    walkthrough: {
      intro:
        "`gwq` is to git worktrees what `ghq` is to `git clone` — a unified directory hierarchy of worktrees you can fuzzy-jump into. The TOML config is generated from a Nix attrset via `pkgs.formats.toml`, so the source of truth is still this Nix file even though gwq reads TOML.",
    },
  },

  "home/mcp.nix": {
    about: "MCP servers via natsukium/mcp-servers-nix — exposed to Claude Code.",
    tags: ["ai", "mcp"],
    walkthrough: {
      intro:
        "MCP (Model Context Protocol) lets Claude Code talk to external tools. `natsukium/mcp-servers-nix` is the registry / module hub, and this file declares which servers to enable. Chrome DevTools isn't covered by the registry's built-in modules, so it slots in via the `settings.servers` freeform escape hatch.",
    },
  },

  "home/octorus.nix": {
    about: "Octorus (GitHub review TUI) config — editor, diff theme, key bindings.",
    tags: ["github", "review"],
    walkthrough: {
      intro:
        "Octorus is a personal TUI for GitHub code review. Like `gwq`, its TOML config is generated from a Nix attrset, so editor (`code`), diff theme, and the keybindings for approve / request-changes / comment / suggestion all live here in one place.",
    },
  },

  "home/playwright.nix": {
    about: "Temporary npm-global Playwright CLI install via home.activation.",
    tags: ["test"],
    walkthrough: {
      intro:
        "`@playwright/cli` isn't in nixpkgs yet. As a workaround, a `home.activation` hook lazily installs it into `$HOME/.npm-global` only when missing. This file should disappear once nixpkgs ships the package.",
    },
  },

  "home/starship.nix": {
    about: "Starship prompt — Nushell integration, newline and module-ordering tweaks.",
    tags: ["shell", "prompt"],
    walkthrough: {
      intro:
        "Starship is the cross-shell prompt. This module enables it for Nushell, adds a leading newline so the prompt always has breathing room above it, and tweaks module ordering so directory and git status appear in the most useful slots.",
    },
  },

  "home/vscode.nix": {
    about: "VS Code settings + keybindings synced from the vscode-settings repo.",
    tags: ["editor"],
    walkthrough: {
      intro:
        "VS Code's `settings.json` and `keybindings.json` are sourced from a separate repo (`naitokosuke/vscode-settings`), pinned via the flake input. The interesting bit is that the keybinding file upstream is JSONC (comments included), and this module strips them with Nix builtins — no Python or Node at activation time.",
      sections: [
        {
          title: "JSONC → JSON via Nix builtins",
          prose:
            "`builtins.readFile` reads the raw JSONC, then `lib.splitString` + `builtins.filter` drop any line that matches `[[:space:]]*//.*`. The result is valid JSON that VS Code can load directly. No external tools, no activation-time scripts.",
        },
      ],
    },
  },

  "home/zoxide.nix": {
    about: "zoxide — a learning `cd`. Integrated into Zsh and Nushell.",
    tags: ["shell", "navigation"],
    walkthrough: {
      intro:
        "`zoxide` watches which directories you `cd` into and learns frequency + recency, then exposes a `z` command that jumps to the best match for a fragment. Both Zsh and Nushell integrate, so the same history surfaces in either shell.",
    },
  },

  "home/shell/default.nix": {
    about: "Aggregator that pulls in Nushell (interactive) and Zsh (login).",
    tags: ["shell", "index"],
    walkthrough: {
      intro:
        "The shell story is dual: Nushell is the interactive shell inside Ghostty (structured-data, modern), while Zsh remains the *login* shell so VS Code extensions, SSH, and Claude Code see a familiar POSIX environment. This file just imports both.",
    },
  },

  "home/shell/common.nix": {
    about: "Shared shell config — PATH, env vars, aliases, Homebrew-forbidden formulae.",
    tags: ["shell", "common"],
    walkthrough: {
      intro:
        "Anything that should be identical in Nushell and Zsh — `$PATH` ordering, environment variables, aliases — lives here. Also defines a `homebrewForbiddenFormulae` list (`bun`, `claude`, …) so `brew install` can never accidentally shadow a Nix-managed binary on `$PATH`.",
    },
  },

  "home/shell/nushell.nix": {
    about: "Nushell — interactive shell inside Ghostty.",
    tags: ["shell"],
    walkthrough: {
      intro:
        "Nushell is the interactive shell. Unlike POSIX shells, every command's output is structured data, which is a much better fit for the kinds of data-shaped pipelines this dotfiles repo encourages. Some IDE integrations still need POSIX, which is why Zsh sticks around as the login shell.",
    },
  },

  "home/shell/zsh.nix": {
    about: "Zsh — login shell for VS Code extensions, SSH, and Claude Code.",
    tags: ["shell"],
    walkthrough: {
      intro:
        "Zsh handles login-shell responsibilities — anything that spawns a non-interactive shell to read `$PATH` and environment variables sees Zsh, not Nushell. `$PATH` is set in `.zprofile` (not `.zshenv`) per the home-manager best-practice, so it loads once at login and isn't redundantly re-evaluated.",
    },
  },

  "docs/AGENTS.md": {
    about: "Agent operating guide for the Vite+ frontend.",
    tags: ["docs", "web"],
    walkthrough: {
      intro:
        "This file is read by automated agents (Claude Code and friends) when they touch the web app. It points at the Vite+ docs, then enumerates the validation flow — `vp install` → `vp check` → `vp test` — every change should go through. The site you're looking at right now is built by the very same `vp` toolchain.",
    },
  },
};
