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
        "The README is the single page a newcomer should be able to read end-to-end and reproduce this machine. It states the OS prerequisites (Apple Silicon + Lix), the bootstrap command, the directory split between `hosts/` and `home/`, and the everyday `sudo darwin-rebuild` workflow.",
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
            "Install the Xcode CLT and Lix, clone, then run nix-darwin once through `sudo nix run nix-darwin -- switch --flake .#<host>`. The `--extra-experimental-features` flag is only needed for that first run, before `hosts/common/nix.nix` has turned flakes on globally; after it, `sudo darwin-rebuild switch` takes over — activation runs as root.",
          lines: [14, 35],
        },
        {
          title: "Packages outside nixpkgs",
          prose:
            "Tools nixpkgs doesn't ship are packaged under `pkgs/` and version-tracked by nvfetcher, with a daily workflow opening the update PR. vite-plus is the one package in two halves — the `vp` launcher and the JavaScript toolchain it delegates to — which must stay on the same version.",
          lines: [67, 86],
        },
      ],
    },
  },

  "flake.nix": {
    about: "Entry point of the Nix flake. Inputs and darwinConfigurations.",
    tags: ["flake", "entry"],
    walkthrough: {
      intro:
        "`flake.nix` is the single source of truth for the whole environment. It pins every upstream input (nixpkgs, nix-darwin, home-manager, nix-homebrew, Homebrew itself and its taps, and a handful of tool and settings repositories), then assembles `darwinConfigurations` for each Mac. `darwin-rebuild` resolves everything from this file alone — given the same `flake.lock`, each host evaluates to the same system every time.",
      sections: [
        {
          title: "Inputs",
          prose:
            "Flake inputs that depend on nixpkgs `follow` this one, so the world ships one pkgs set. `flake = false` inputs are locked source snapshots read at eval time: `brew-src`, the Homebrew taps (`homebrew-core` included, because `brew bundle` loads it whenever `HOMEBREW_NO_INSTALL_FROM_API` is set), `vscode-settings`, `skill-skill-skill`, and `nu-scripts`. `brew-src` pins Homebrew itself at a release tag (7.0.1) ahead of the one nix-homebrew locks, and nix-homebrew's own `brew-src` follows it. `llm-agents` supplies Claude Code and `mcp-servers-nix` the MCP module.",
          lines: [4, 67],
        },
        {
          title: "One package set, two roots",
          prose:
            "The overlays and the Nixpkgs config are named once and used twice: by the `pkgs` the flake's own outputs are built from, and by the inline module every host loads. `customPackages` is the single entry into `./pkgs`, so the `packages` output and the overlay are visibly the same function rather than two similar-looking expressions — a custom package that grows a dependency on another custom package, or on an unfree one, cannot build one way through `nix build .#<pkg>` and another through `darwin-rebuild switch`.",
          lines: [80, 102],
        },
        {
          title: "mkDarwinConfig",
          prose:
            "A small helper that builds one `darwinSystem` per host. `specialArgs` passes the flake `inputs` to every module, and `hosts/common/home-manager.nix` forwards them to home-manager as well. An inline module pins `aarch64-darwin` and applies the shared `nixpkgsConfig` and `overlays` defined above. The module is a `{ config, ... }:` function so `system.primaryUser` derives from `config.naitokosuke.username` rather than a hardcoded literal. `./modules/naitokosuke` loads first, then the home-manager and nix-homebrew darwin modules, `hosts/common`, and `hosts/<hostName>`.",
          lines: [109, 133],
        },
        {
          title: "Per-host configurations",
          prose:
            "`darwinConfigurations` is built by mapping the `hosts` list (defined above `mkDarwinConfig`) through it with `nixpkgs.lib.genAttrs`. Adding a new Mac is a one-line append to that list — plus a `hosts/<host>/default.nix` for the diff — with no per-host `darwinConfigurations` attribute to hand-write.",
          lines: [136, 136],
        },
        {
          title: "Custom packages output",
          prose:
            "`packages.<system>` exposes the same `./pkgs` set that the overlay injects, so `nix build .#gwq` works standalone — handy for testing a derivation without evaluating a whole darwin configuration.",
          lines: [138, 138],
        },
        {
          title: "Formatter",
          prose:
            "`nix fmt` runs nixfmt through treefmt-nix, with `flake.nix` marking the project root. It formats through the configured `pkgs` too, so there is no second package set left in the flake.",
          lines: [140, 143],
        },
      ],
    },
  },

  "nvfetcher.toml": {
    about: "nvfetcher config — tracks upstream releases of tools not in nixpkgs.",
    tags: ["packages", "automation"],
    walkthrough: {
      intro:
        "The version tracker for CLI tools that nixpkgs doesn't ship. Each entry names an upstream to watch and an artifact to fetch; running `nix run nixpkgs#nvfetcher -- -o pkgs/_sources` resolves the latest release and regenerates `pkgs/_sources/generated.nix` with pinned URLs and hashes. No more hand-editing versions or copy-pasting sha256 values.",
      sections: [
        {
          title: "Release binaries",
          prose:
            '`src.github` watches `d-kuro/gwq` releases; `fetch.url` downloads the `gwq_Darwin_arm64.tar.gz` asset for that tag (`$ver` is substituted). Each entry is named after the exact asset it pins, so adding another platform later is a new entry, not a rewrite. `gh-sub-issue` ships a bare binary whose asset name embeds the version without the tag\'s `v` prefix, so `src.prefix = "v"` strips it at the tracker level and the URL re-adds it where needed.',
          lines: [4, 13],
        },
        {
          title: "vite-plus from npm",
          prose:
            "The GitHub release carries only the `vp` launcher, while the JavaScript toolchain it delegates to is built separately from `pkgs/vite-plus-runtime`. Both halves are published to npm under one version, so the entry watches GitHub tags but fetches the launcher's npm tarball, with the prefix stripped so `$ver` is exactly that npm version.",
          lines: [15, 23],
        },
        {
          title: "playwright-cli from source",
          prose:
            "`@playwright/cli` has no release binaries, so `fetch.github` pins the source tree at the tag instead, and `pkgs/playwright-cli.nix` builds it with `buildNpmPackage`.",
          lines: [25, 30],
        },
        {
          title: "frog",
          prose:
            "frog's tags carry a project-name prefix (`frog@`) that `src.prefix` strips, and its release asset is a gzipped single binary.",
          lines: [32, 37],
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

  "pkgs/frog.nix": {
    about: "frog (friction logging for agents) — installs the gzipped darwin-arm64 binary.",
    tags: ["packages", "cli"],
    walkthrough: {
      intro:
        "frog records the friction coding agents run into, so it can be reviewed later. Upstream releases a gzipped single binary rather than an archive, so the derivation decompresses it itself.",
      sections: [
        {
          title: "Fetch and install",
          prose:
            "The asset is a single gzipped file, not an archive, so `dontUnpack` skips stdenv's unpack phase and `installPhase` gunzips the source straight into `$out/bin/frog`, then makes it executable.",
          lines: [12, 20],
        },
        {
          title: "Install check",
          prose:
            "`frog --version` has to run successfully, which confirms the decompressed binary actually executes on this platform.",
          lines: [22, 27],
        },
      ],
    },
  },

  "pkgs/gh-sub-issue.nix": {
    about: "gh-sub-issue — gh extension installed from its prebuilt release binary.",
    tags: ["packages", "github"],
    walkthrough: {
      intro:
        "A gh extension for creating and listing GitHub sub-issues. `home/gh.nix` registers it through `programs.gh.extensions`, which links this package's `bin/` under `~/.local/share/gh/extensions/<pname>` — so `pname` and the binary name both have to be `gh-sub-issue`. The release asset is a bare executable, so there is nothing to unpack.",
      sections: [
        {
          title: "Fetch and install",
          prose:
            "`dontUnpack` plus `install -Dm755` places the pinned binary as `$out/bin/gh-sub-issue`. The version comes from nvfetcher with the tag's `v` already stripped.",
          lines: [10, 21],
        },
      ],
    },
  },

  "pkgs/gwq.nix": {
    about: "gwq (worktree counterpart to ghq) — installs the prebuilt darwin-arm64 tarball.",
    tags: ["packages", "git"],
    walkthrough: {
      intro:
        "Upstream publishes prebuilt binaries, so the derivation installs the `gwq_Darwin_arm64.tar.gz` asset that nvfetcher pinned. The configuration lives in `home/gwq.nix`.",
      sections: [
        {
          title: "Fetch and install",
          prose:
            'The tarball is flat — the `gwq` binary sits at its root — so `sourceRoot = "."` keeps the unpacker in place, and `versionCheckHook` confirms the binary reports the pinned version.',
          lines: [8, 23],
        },
      ],
    },
  },

  "pkgs/playwright-cli.nix": {
    about: "playwright-cli — built from source with buildNpmPackage and importNpmLock.",
    tags: ["packages", "test"],
    walkthrough: {
      intro:
        "The one source build in `./pkgs`: `@playwright/cli` is published only on npm, with no prebuilt release binaries, so nvfetcher pins the GitHub source tree and `buildNpmPackage` installs it. The TODO on top marks the exit plan — once nixpkgs ships it (NixOS/nixpkgs#490230), this file and its nvfetcher entry give way to `pkgs.playwright-cli`.",
      sections: [
        {
          title: "Dependencies from the upstream lockfile",
          prose:
            "`importNpmLock` reads `package-lock.json` straight out of the pinned source, so there's no `npmDepsHash` to update by hand after each nvfetcher bump (issue #411). `src` is bound in a `let` because both the derivation and `importNpmLock` need the same tree. `dontNpmBuild` skips `npm run build`.",
          lines: [13, 28],
        },
        {
          title: "Browsers stay runtime-managed",
          prose:
            "Browsers are left to Playwright's own cache. Pinning nixpkgs' `playwright-driver.browsers` would pair them with a different Playwright version than the one vendored here.",
          lines: [30, 32],
        },
      ],
    },
  },

  "pkgs/vite-plus.nix": {
    about: "vite-plus (vp) — the prebuilt launcher plus the JavaScript toolchain it runs.",
    tags: ["packages", "cli"],
    walkthrough: {
      intro:
        '`vp` itself is only a Rust launcher. Every subcommand that does real work (`dev`, `build`, `check`, `fmt`, …) is handed to a JavaScript toolchain that vp looks for at `<prefix>/node_modules/vite-plus`, next to its own executable. Without it they all fail with "Cannot find module" (issue #413), so this derivation also builds the npm dependency tree from `pkgs/vite-plus-runtime` and installs it alongside. The approach follows ryoppippi/nix-vite-plus. The TODO on top marks the exit plan: once nixpkgs ships vite-plus (NixOS/nixpkgs#533925), this file, `pkgs/vite-plus-runtime`, and the nvfetcher entry give way to `pkgs.vite-plus`.',
      sections: [
        {
          title: "The JavaScript toolchain",
          prose:
            "`importNpmLock.buildNodeModules` materialises `node_modules` from the lockfile in `pkgs/vite-plus-runtime`, on `nodejs_26` to match the system Node. `postInstall` then patches `vp create` so templates it copies out of the store come out writable, drops `node_modules/.bin` so a second oxlint / oxfmt never reaches `$PATH`, and deletes npm's `.package-lock.json`, whose store references would otherwise keep around 300 MB of source tarballs in the closure.",
          lines: [36, 66],
        },
        {
          title: "Refusing to drift",
          prose:
            "The launcher and the toolchain are two halves of one release. nvfetcher bumps the launcher but never touches the lockfile, so `lib.throwIf` fails evaluation whenever the two versions disagree, printing the commands that regenerate the lockfile. The nvfetcher workflow runs those same commands, so update PRs arrive with both halves in step.",
          lines: [68, 82],
        },
        {
          title: "Install",
          prose:
            "The launcher comes from the npm platform tarball (everything under `package/`). `node_modules` is symlinked next to it rather than copied, `wrapProgram` puts Nix's Node on `$PATH` for the JavaScript half, and `vpr` / `vpx` are linked the way the official installer's `vp env setup` would — vp dispatches on `argv[0]` (`vpr` → `vp run`, `vpx` → `vp dlx`), which the wrapper preserves. The `node` / `npm` / `npx` / `corepack` shims that step also creates are deliberately omitted: they belong to vp's Node version manager and would shadow Nix-managed Node. Finally, a `.vp-setup-complete` marker next to the binary stops vp from installing a second, unmanaged copy of itself into `$HOME` on first start (issue #434).",
          lines: [94, 125],
        },
        {
          title: "An install check that runs the toolchain",
          prose:
            "`vp --version` is answered by the launcher alone, so it passes even when every JavaScript subcommand is broken. The check runs `vp fmt --help` from an empty directory instead, which only succeeds when the launcher finds the toolchain installed next to it. It runs against a throwaway `$HOME` holding the same `shimMode` config as `home/vite-plus.nix`, and fails if vp wrote anything into it, so a change in how upstream skips self-setup is caught at build time rather than in the user's home.",
          lines: [127, 157],
        },
      ],
    },
  },

  ".github/workflows/nvfetcher.yml": {
    about: "Daily CI — reruns nvfetcher and opens an update PR when pins change.",
    tags: ["ci", "automation"],
    walkthrough: {
      intro:
        "The automation half of the nvfetcher story. Every morning at 08:00 JST (or on manual dispatch) CI reruns nvfetcher; if any tracked tool released a new version, the regenerated `pkgs/_sources/` — plus the vite-plus runtime lockfile that has to move with it — lands in an auto-created pull request instead of anyone remembering to bump versions. Requires the repo setting that lets Actions create PRs.",
      sections: [
        {
          title: "Running nvfetcher",
          prose:
            "A throwaway keyfile passes `GITHUB_TOKEN` to nvfetcher so release lookups aren't rate-limited, then `nix run nixpkgs#nvfetcher -- -o pkgs/_sources` regenerates the pins — the same command used locally, so CI and laptop can never disagree.",
          lines: [21, 24],
        },
        {
          title: "Syncing the vite-plus runtime",
          prose:
            "nvfetcher only knows about the vite-plus launcher, but `pkgs/vite-plus.nix` refuses to evaluate unless the runtime lockfile pins the same version. So CI reads the new version from `generated.json`, sets it as the runtime's `vite-plus` dependency, and regenerates `package-lock.json` without installing anything.",
          lines: [26, 40],
        },
        {
          title: "The update PR",
          prose:
            "`peter-evans/create-pull-request` commits only `pkgs/_sources/` and `pkgs/vite-plus-runtime/` to a fixed `nvfetcher-update` branch — repeated runs update the same PR rather than piling up new ones, and the branch deletes itself on merge.",
          lines: [42, 53],
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
    about:
      "Typed personal-constants module — username, full name, email, home and source directories.",
    tags: ["module", "config"],
    walkthrough: {
      intro:
        "A small NixOS-module-style namespace that centralizes the personal literals the rest of the tree needs. It declares typed `naitokosuke.{username,fullName,email,homeDirectory,srcDirectory}` options and sets their defaults, so every other module reads `config.naitokosuke.*` instead of hardcoding `naitokosuke`. It's loaded into both nix-darwin (via the flake `modules` list) and home-manager (via `home-manager.sharedModules`), so both trees resolve the same values — and a host can override any of them in one place.",
      sections: [
        {
          title: "Typed options",
          prose:
            "Each constant is an `mkOption` with `type = types.str` and a description, so the values are self-documenting and type-checked rather than bare strings copied around the repo.",
          lines: [13, 34],
        },
        {
          title: "Defaults",
          prose:
            "`config.naitokosuke` sets the defaults for this user. `srcDirectory` is derived from `homeDirectory` and is the one root that ghq, gwq, nh, and the Claude Code rule and skill links all build their paths from. Because they're module options, a per-host module can override any field without touching the call sites that consume them.",
          lines: [36, 42],
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
        "`gomi` is a safer `rm` that moves files to a trash directory. This module installs a user `launchd` agent that runs `gomi --prune=45d,orphans` once a week, so the trash doesn't accumulate forever. gomi's own settings live in `home/gomi.nix`.",
      sections: [
        {
          title: "The launchd agent",
          prose:
            "`ProgramArguments` resolves `gomi` from the Nix store via `lib.getExe` — no `$PATH` dependency. `StartCalendarInterval` runs the prune every Sunday at 03:00; the agent is owned by the user, so it doesn't need root. No stdout/stderr paths are set, since gomi already records each prune in its own log (`~/.local/share/gomi/debug.log`).",
          lines: [7, 24],
        },
      ],
    },
  },

  "hosts/common/home-manager.nix": {
    about: "Bridge from nix-darwin to home-manager.",
    tags: ["bridge", "home-manager"],
    walkthrough: {
      intro:
        "Wires `home-manager` into nix-darwin so the user-side configuration ships alongside the system. `useGlobalPkgs` and `useUserPackages` keep both layers on the same nixpkgs instance, and a pre-existing file in the way of a managed one is renamed with a `.backup` extension rather than failing activation. `sharedModules` injects the `modules/naitokosuke` personal-constants module and `mcp-servers-nix`'s home-manager module into the home-manager tree, and `home/` (its `default.nix`) is imported as the user's home configuration. `users.users.<name>.home` is set explicitly because home-manager derives `home.username` / `home.homeDirectory` from it, and nix-darwin leaves it null by default (issue #321). `extraSpecialArgs` forwards nix-darwin's `specialArgs` minus its `modulesPath`, so home modules receive the flake `inputs` from `flake.nix` directly (issue #324).",
    },
  },

  "hosts/common/homebrew.nix": {
    about: "Declarative Homebrew via nix-homebrew. GUI apps as Casks.",
    tags: ["homebrew", "gui"],
    walkthrough: {
      intro:
        "macOS GUI apps don't fit Nix's model cleanly, so we keep a thin Homebrew layer for them. `nix-homebrew` provides the bridge — Homebrew itself, the taps, and the desired cask set are all declared, then materialised on every `darwin-rebuild`.",
      sections: [
        {
          title: "Sudo prompts go to a dialog",
          prose:
            "Homebrew resets sudo's timestamp on every invocation, and some cask uninstall steps shell out to sudo repeatedly, so a cask upgrade during activation would ask for a password over and over on the very terminal `nom` is repainting. `SUDO_ASKPASS` points at a small `osascript` dialog instead — Homebrew adds `-A` to sudo whenever it's set, so the prompt appears as a GUI dialog that says what it's for (issue #416).",
          lines: [23, 35],
        },
        {
          title: "Homebrew ahead of nix-homebrew",
          prose:
            "`nix-homebrew` installs and pins the Homebrew binary itself via Nix. That binary comes from the `brew-src` input in `flake.nix`, pinned at 7.0.1 ahead of the version nix-homebrew locks (issue #432). nix-homebrew labels its package with the ref from its own `flake.lock`, so the store path would otherwise name that ref rather than the one pinned here; `package` rebuilds the name and version from this repository's `flake.lock` (`brewVersion` at the top of the file) so they match the ref pinned in `flake.nix`. A flake input reaches a module as a source tree, and the tag it is pinned to is not part of that interface — hence reading the lock as data, via `inputs.self` rather than a relative path, with a `throw` that explains itself if `brew-src` is ever pinned to something other than a tag.",
          lines: [39, 48],
        },
        {
          title: "Pinned, read-only taps",
          prose:
            "`taps` pulls every tap from a flake input, so even Homebrew's tap repos are pinned. `mutableTaps = false` makes them read-only — `brew tap` is disabled, and a new tap has to arrive as a flake input.",
          lines: [49, 60],
        },
        {
          title: "Taps and activation policy",
          prose:
            'The Brewfile mirrors the pinned tap list so `brew bundle` cleanup does not untap them. `HOMEBREW_NO_INSTALL_FROM_API` forces cask definitions to come from those pinned taps rather than Homebrew\'s API, and `cleanup = "uninstall"` converges the machine onto exactly the cask list below — new versions arrive via `nix flake update`.',
          lines: [62, 82],
        },
        {
          title: "Casks",
          prose:
            "Everything in `casks` is materialised on `darwin-rebuild`. `productdevbook/tap/portkiller` and `stablyai/orca/orca` show how third-party taps slot in. Orca's cask also ships the `orca` CLI. DockDoor supplies the window switcher and Dock previews. Adrafinil and Orca both update themselves in place, so the flake.lock pin is only the floor version a fresh machine starts from. Adrafinil's cask also requires macOS 26, and its Claude Code hooks are declared in `home/claude.nix`.",
          lines: [84, 108],
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
    about: "Nix runtime — Lix, flakes, weekly nh GC and store optimisation.",
    tags: ["nix", "infra"],
    walkthrough: {
      intro:
        "Configures the Nix daemon itself. Lix replaces upstream Nix, `experimental-features` turns on `nix-command` and `flakes`, a weekly `nh clean all` daemon and `nix.optimise` keep the store in check, and zsh's `/etc` management is delegated to home-manager so Nushell stays the primary interactive shell.",
      sections: [
        {
          title: "Hand zsh to home-manager",
          prose:
            "`nix-darwin` normally rewrites `/etc/zshrc`; disabling that lets home-manager own every dotfile end-to-end. Nushell is the interactive shell in Ghostty, so zsh stays minimal — just the login shell for IDEs / SSH.",
          lines: [10, 14],
        },
        {
          title: "Weekly GC with nh",
          prose:
            "`nix.package = pkgs.lix` opts into the Lix fork of CppNix. Garbage collection doesn't use `nix.gc`: a root launchd daemon runs `nh clean all --keep-since 14d` every Sunday at 03:15. Besides system and user generations, that also drops stale GC roots — forgotten `result` links and nix-direnv profiles — while keeping two weeks of rollback. Running as root means nh never has to elevate itself; home-manager's `programs.nh.clean` isn't used because on Darwin it only cleans user profiles.",
          lines: [16, 32],
        },
        {
          title: "Store optimisation",
          prose:
            "An hour after the GC, `nix.optimise` hard-links identical files across whatever the cleanup left in the store.",
          lines: [33, 40],
        },
        {
          title: "Flakes and trusted users",
          prose:
            '`experimental-features = "nix-command flakes"` turns on flakes globally so every shell can do `nix run`, `nix build`, etc., without `--extra-experimental-features` flags. `trusted-users` adds the primary user next to root, so daemon-level settings such as extra substituters are honoured for them.',
          lines: [42, 46],
        },
        {
          title: "Build provenance",
          prose:
            "`system.configurationRevision` records the flake's git revision (or its dirty revision), so the running system can always be traced back to the commit it was built from.",
          lines: [48, 48],
        },
      ],
    },
  },

  "hosts/common/packages.nix": {
    about: "System-wide CLI packages declared in environment.systemPackages.",
    tags: ["cli", "packages"],
    walkthrough: {
      intro:
        "The system CLI toolbelt. Everything here is on `$PATH` for every user and login shell. The only derivation defined inline is `darwin-rebuild-nom` (pipes `darwin-rebuild` through `nix-output-monitor`); the rest come from nixpkgs, from the nvfetcher-tracked overlay in `./pkgs` (`frog`, `gwq`, `playwright-cli`, `vite-plus`, …).",
      sections: [
        {
          title: "darwin-rebuild-nom wrapper",
          prose:
            "`darwin-rebuild` rejects `--log-format`, and Lix doesn't expose it as a setting either, so a small shell application pipes `darwin-rebuild`'s combined output into `nom` in its default mode, which parses plain Nix output. The result is the same rebuild command with nix-output-monitor's richer progress UI.",
          lines: [4, 13],
        },
        {
          title: "The CLI toolbelt",
          prose:
            "Daily drivers: `gh`, `ghq`, `git`, `fd`, `fzf`, `ripgrep`, `sd`, `tree`, `vim`, `herdr`, and `gomi` as a safer `rm`. JavaScript: `nodejs_26`, `bun`, `pnpm`, `ni`, and `oxfmt`. Language toolchains that should be available outside any project shell: `rustup` (with `cargo-deny`), `uv`, and `idris2`. Nix workflow tools: `nixd`, `devenv`, `nix-output-monitor`, plus the locally-built `darwin-rebuild-nom`. `agent-browser` drives the Homebrew-installed Chrome for browser checks by agents. Claude Code is deliberately absent: the only `claude` on `$PATH` is the sandboxed one from `home/claude-sandbox.nix`. `frog`, `gwq`, `playwright-cli`, and `vite-plus` (`vp`) from the `./pkgs` overlay.",
          lines: [16, 48],
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
        "The entry point for the *user* layer. It imports every per-tool module (atuin, direnv, gh, git, nh, starship, vscode, …) and pins `home.stateVersion`. Adding a new tool means writing a sibling `.nix` and importing it here.",
      sections: [
        {
          title: "Tool modules",
          prose:
            "Each tool gets its own file or directory directly under `home/`. Composing them as a flat list keeps every concern shallow — opening `git.nix` shows the full git story, opening `claude.nix` shows the Claude Code settings, with its rm guard and sandbox in their own siblings.",
          lines: [4, 25],
        },
        {
          title: "State version",
          prose:
            "`home.username` and `home.homeDirectory` aren't set here: home-manager derives them from `users.users`, which `hosts/common/home-manager.nix` fills from `config.naitokosuke`. `home.stateVersion` is pinned at the version this config was first written for — never bump casually.",
          lines: [27, 27],
        },
      ],
    },
  },

  "home/atuin.nix": {
    about: "atuin (synced fuzzy shell history) with Zsh + Nushell integration.",
    tags: ["shell", "history"],
    walkthrough: {
      intro:
        "atuin replaces the shell's built-in history with a synced, fuzzy-searchable SQLite store. Both Zsh and Nushell hook into it, search mode is fuzzy, and the scope is global so the same history surfaces no matter which directory the search starts from. The search UI is compact, 20 lines tall, with a preview of the selected command.",
    },
  },

  "home/claude-rm-guard/default.nix": {
    about:
      "PreToolUse hook that blocks irreversible deletions in shell commands and points to gomi.",
    tags: ["ai", "claude"],
    walkthrough: {
      intro:
        "Instructions in CLAUDE.md or skills can be ignored; a hook runs on every Bash call. This one blocks `rm`, `unlink`, `rmdir`, `shred`, `find -delete` / `-exec rm`, and `git clean` (but not `git rm`, which history can undo), and the reason it returns tells the agent to use `gomi` instead. It is the first of two layers: the Seatbelt sandbox in `home/claude-sandbox.nix` catches whatever slips past, but cannot tell deletion apart from the rename `gomi` relies on, so forcing `gomi` has to happen here.",
      sections: [
        {
          title: "Parsing instead of matching",
          prose:
            "The command is parsed with `shfmt --to-json` (zsh dialect, bash as a fallback), and `classify.jq` walks every call in the AST, so `$(...)`, backticks, pipelines, and `&&` chains are all covered. Wrappers such as `sudo`, `env`, `xargs`, `timeout`, and `find -exec` are peeled off before the command name is checked, and `sh -c` / `eval` bodies go through the parser again. Anything that cannot be checked — unparsable input, a script read from stdin, a dynamically built `-c` body — is blocked rather than let through.",
          lines: [17, 79],
        },
        {
          title: "Denying, and failing closed",
          prose:
            'A block is returned as a JSON `permissionDecision: "deny"`, which Claude Code shows as a denied call rather than a hook error; exit code 2 is the fallback if the JSON cannot be written. Any other non-zero exit would be a non-blocking error that lets the command run, so an `ERR` trap turns unexpected failures into a deny as well.',
          lines: [25, 45],
        },
        {
          title: "Registration",
          prose:
            "The hook is added to `programs.claude-code.settings.hooks.PreToolUse` for the `Bash` and `Monitor` tools. home-manager merges it with the `ExitPlanMode` hook in `home/claude.nix`.",
          lines: [82, 93],
        },
      ],
    },
  },

  "home/claude-sandbox.nix": {
    about:
      "Runs every Claude Code session under a Seatbelt profile that limits where it can write.",
    tags: ["ai", "claude"],
    walkthrough: {
      intro:
        "`claude` is wrapped so the whole process — its Bash commands, hooks, and MCP servers — runs under `/usr/bin/sandbox-exec` with a profile generated here. Any deletion that slips past the Bash hooks (`/bin/rm` from a script, `fs.rmSync`, and so on) still cannot touch files outside the directory the session started in. Seatbelt cannot block deletion alone: denying unlink also blocks the rename `gomi` relies on, so this layer limits *where* writes land rather than *what* they are. The approach follows Warashi/cage, minus the extra binary.",
      sections: [
        {
          title: "The profile",
          prose:
            "Everything is allowed except file writes, which are limited to the per-user temp dirs, `/private/tmp`, Claude Code's own state, the login keychain, `gomi`'s trash and log directories, and toolchain caches that are safe to lose. On top of that come the working directory, the git common dir, and — through a regex rule — any `<main checkout>---<branch>` sibling, so gwq can create and use worktrees next to the main checkout while the main checkout itself and other repositories stay read-only. These are only known at launch, so they arrive as SBPL parameters instead of being spliced into the profile text.",
          lines: [18, 56],
        },
        {
          title: "Wrapping claude",
          prose:
            "`programs.claude-code.package` is a script that resolves the parameters — the git common dir lets commits from a worktree reach the main checkout's `.git`, and the main checkout path is regex-escaped for the sibling rule — and execs the real binary through `sandbox-exec`. home-manager's own wrapper — plugin dir, MCP servers — sits on top, so it ends up inside the sandbox too. The script carries Claude Code's version, because home-manager picks its plugin mechanism from the package version and falls back to the legacy `--plugin-dir` wrapper without one.",
          lines: [59, 89],
        },
      ],
    },
  },

  "home/claude.nix": {
    about: "Claude Code — declarative settings.json plus live-linked rules and skills.",
    tags: ["ai", "claude"],
    walkthrough: {
      intro:
        "Claude Code's user-level configuration, in two deliberately different styles. `settings.json` is generated by home-manager's `programs.claude-code` as a read-only store symlink, so Nix is the single source of truth and runtime edits aren't persisted back. Rules, `CLAUDE.md`, and skills are the opposite: out-of-store symlinks into working copies of separate repositories, so editing them takes effect without a rebuild.",
      sections: [
        {
          title: "Adrafinil hooks",
          prose:
            "Adrafinil keeps the Mac awake only while an agent turn is running. Its one-click installer would write into the read-only `settings.json`, so the seven handlers from upstream's `ClaudeCodeIntegration.swift` are copied here by hand. `UserPromptSubmit` / `Stop` bracket each turn, the sub-agent pair outlives the parent turn, and `Notification`, `SessionEnd` and `SessionStart` cover the turn-ends that fire no `Stop`. The commands match upstream verbatim, which is how Adrafinil recognises them as its own, and they call the in-bundle CLI rather than the `/usr/local/bin` symlink the app creates later.",
          lines: [8, 68],
        },
        {
          title: "settings.json",
          prose:
            "Global preferences — theme, editor mode, notifications, Japanese spinner verbs. The binary comes from Nix via `llm-agents`, so `env` turns off Claude Code's own auto-updater and installation checks.",
          lines: [74, 103],
        },
        {
          title: "Permissions",
          prose:
            "`permissions.deny` blocks reading credentials (`.env*`, `secrets/`, `~/.ssh`, `~/.aws`, `~/.gnupg`), wiping `/` or `~`, force-pushing, and raw `curl` / `wget` in favour of WebFetch with an explicit domain — plus a tongue-in-cheek ban on `perl` and `python`.",
          lines: [104, 136],
        },
        {
          title: "Plan hook",
          prose:
            "A `PreToolUse` hook on `ExitPlanMode` opens the newest plan file in VS Code, so a plan can be read in the editor before it's approved. The Adrafinil handlers are merged in alongside it.",
          lines: [137, 150],
        },
        {
          title: "Rules and skills",
          prose:
            "`mkOutOfStoreSymlink` links `~/.claude/rules` and `~/.claude/CLAUDE.md` into `rule-rule-rule`. Skills are linked one by one, because `programs.claude-code` installs its generated MCP plugin into `~/.claude/skills` and fails when that directory is itself a symlink. Pure evaluation can't read the live working tree, so skill names come from the locked `skill-skill-skill` input; the links still point at the working tree, so only adding or removing a skill needs `nix flake update skill-skill-skill`.",
          lines: [153, 184],
        },
      ],
    },
  },

  "home/direnv.nix": {
    about: "direnv + nix-direnv, with Nushell integration.",
    tags: ["dev-env"],
    walkthrough: {
      intro:
        "`direnv` + `nix-direnv` is how per-project shells materialise — drop a `.envrc` into a project, run `direnv allow`, and the right `nix shell` or `devenv` env loads on `cd`, in Nushell too. nix-direnv caches the evaluated environment and roots it against garbage collection, so entering a project is instant after the first load.",
    },
  },

  "home/gh.nix": {
    about: "GitHub CLI config plus the gh-sub-issue extension.",
    tags: ["github", "cli"],
    walkthrough: {
      intro:
        "`gh` is the GitHub CLI; this module configures it — SSH as the git protocol, vim as the editor, and a `co` alias for `pr checkout` — and ships the `gh-sub-issue` extension. The extension isn't in nixpkgs, so it comes from `./pkgs` as the official prebuilt binary, version-tracked by nvfetcher.",
    },
  },

  "home/gh-dash.nix": {
    about: "gh-dash — a terminal dashboard for PRs, issues, and notifications.",
    tags: ["github", "cli"],
    walkthrough: {
      intro:
        "gh-dash is a TUI dashboard for GitHub. The home-manager module installs it and registers it as a gh extension, so it runs as both `gh-dash` and `gh dash`. Everything else in the file is the dashboard itself, declared as a Nix attrset.",
      sections: [
        {
          title: "Sections",
          prose:
            "Pull requests split into mine, the ones waiting on my review, and everything else I'm involved in; issues into mine, assigned, and involved. Notifications get a tab per reason — author, participating, mention, review requested, and so on.",
          lines: [11, 72],
        },
        {
          title: "Defaults and layout",
          prose:
            "It opens on the PR view with the preview pane showing, lists 20 items per view, and uses `LGTM` as the approve comment. Assignee and base-branch columns are hidden to leave room for the rest.",
          lines: [77, 117],
        },
      ],
    },
  },

  "home/ghostty.nix": {
    about: "Ghostty terminal — Nushell shell, Catppuccin Mocha theme.",
    tags: ["terminal"],
    walkthrough: {
      intro:
        "Ghostty is the primary terminal. The actual binary comes from Homebrew Cask (`package = null` disables the Nix-side install to avoid double-installing), while the config is declared here: Nushell as a login shell, the Catppuccin Mocha theme, and ligatures turned off via `font-feature`.",
      sections: [
        {
          title: "Shift+Enter",
          prose:
            "Ghostty implements fixterms, so Shift+Enter sends an escape sequence — which breaks multi-line input in Claude Code. The keybind makes it send a literal newline instead, matching iTerm2.",
          lines: [21, 26],
        },
      ],
    },
  },

  "home/git.nix": {
    about: "Global git config — identity, ignores, and quality-of-life defaults.",
    tags: ["git"],
    walkthrough: {
      intro:
        "The user-global git config, declarative. The commit identity comes from `config.naitokosuke`, so the name and email are the same values the rest of the tree uses.",
      sections: [
        {
          title: "Global ignores",
          prose:
            "Beyond `.DS_Store` and CodeTour's `.tours`, the list covers personal scratch files (`*.memo.local.md`, `___naito___`), `.claude/settings.local.json`, the `___config___` dummy file that VS Code's file nesting hangs config files under, and `.agents/` for frog's friction logs — kept as a directory pattern so a repository that wants them tracked can re-include it.",
          lines: [9, 22],
        },
        {
          title: "Commit signing",
          prose:
            "Commits and tags are signed by default with `~/.ssh/id_ed25519`, the same key `home/ssh.nix` uses for GitHub, so GitHub marks them Verified and nobody can pass off a commit as this identity. The public key also has to be registered on GitHub as a signing key, which is the one step outside Nix.",
          lines: [23, 29],
        },
        {
          title: "Defaults",
          prose:
            "`histogram` diffs, `zdiff3` conflict markers, `rerere`, rebase on pull with auto-stash, `push.autoSetupRemote`, and `fetch.prune`. Branches sort by recent commit, non-ASCII filenames print verbatim, `ghq.root` is `~/src`, and GitHub HTTPS URLs are rewritten to SSH.",
          lines: [30, 50],
        },
      ],
    },
  },

  "home/gomi.nix": {
    about: "gomi user config — trash location, forbidden paths, TUI styling.",
    tags: ["cli", "config"],
    walkthrough: {
      intro:
        "The user half of gomi, the trash-can alternative to `rm`; the package is in `hosts/common/packages.nix` and the weekly prune agent in `hosts/common/gomi.nix`. The YAML config is generated from a Nix attrset via `pkgs.formats.yaml`, so the source of truth stays in Nix.",
      sections: [
        {
          title: "Trash",
          prose:
            "Trashed files go to `~/.gomi`, and `forbidden_paths` refuses to trash system directories, `/`, or other trash locations. Restores ask for confirmation, and permanent deletion is disabled.",
          lines: [19, 47],
        },
        {
          title: "History and logging",
          prose:
            "The restore list covers the past year and skips `.DS_Store`. Debug logging is on, rotated at 10 MB with three files kept.",
          lines: [92, 111],
        },
      ],
    },
  },

  "home/gwq.nix": {
    about: "gwq (worktree-flavoured ghq) configured via xdg.configFile-generated TOML.",
    tags: ["git", "workflow"],
    walkthrough: {
      intro:
        "`gwq` is to git worktrees what `ghq` is to `git clone` — a unified directory hierarchy of worktrees you can fuzzy-jump into. The binary comes from `./pkgs`; the TOML config is generated from a Nix attrset via `pkgs.formats.toml`, so the source of truth is still this Nix file even though gwq reads TOML.",
      sections: [
        {
          title: "Where worktrees land",
          prose:
            "`worktree.basedir` is `~/src`, the same root as ghq, and the naming template appends `---<branch>` to the repository path. Each worktree therefore sits right beside the clone it came from.",
          lines: [15, 18],
        },
      ],
    },
  },

  "home/mcp.nix": {
    about: "MCP servers via natsukium/mcp-servers-nix — exposed to Claude Code.",
    tags: ["ai", "mcp"],
    walkthrough: {
      intro:
        "MCP (Model Context Protocol) lets Claude Code talk to external tools. `natsukium/mcp-servers-nix` provides the registry through its home-manager module (injected via `sharedModules`), `programs.mcp` collects the servers, and `enableMcpIntegration` hands them to Claude Code. The one server, Adrafinil's `keep_awake`, isn't covered by the registry's built-in modules, so it slots in via the `settings.servers` freeform escape hatch and runs the CLI inside the Homebrew-installed app bundle. It lets an agent keep the Mac awake for work that outlives its turn, which the hooks in `home/claude.nix` do not cover.",
    },
  },

  "home/nh.nix": {
    about: "nh — Nix CLI helper, pointed at this flake for `nh darwin switch`.",
    tags: ["nix", "cli"],
    walkthrough: {
      intro:
        "nh wraps rebuilds with nix-output-monitor progress and shows a closure diff before activating. Garbage collection isn't configured here: it runs as a root `nh clean all` daemon in `hosts/common/nix.nix`, because `programs.nh.clean` only cleans user profiles on Darwin.",
      sections: [
        {
          title: "Pointing nh at this flake",
          prose:
            "`darwinFlake` is this checkout under the ghq root, so `nh darwin switch` picks `darwinConfigurations.<hostname>` without a `--flake` argument. `home.sessionVariables` only reaches zsh, so `NH_DARWIN_FLAKE` is set again for Nushell.",
          lines: [12, 22],
        },
      ],
    },
  },

  "home/playwright.nix": {
    about: "Playwright's browser cache, moved off the directory macOS purges.",
    tags: ["javascript", "test"],
    walkthrough: {
      intro:
        "Playwright downloads Chromium, its headless shell and ffmpeg — around 550 MB — into a machine-wide cache it manages itself, and on macOS that cache lands in `~/Library/Caches/ms-playwright`. macOS counts everything under `~/Library/Caches` as purgeable space and reclaims it silently under disk pressure, browsers included. Nothing notices: they aren't npm packages, so no lockfile describes them and `pnpm install` still reports itself up to date — the first symptom is a browser test failing with `Executable doesn't exist at …` in a project nothing has changed in, and recovery is a ~280 MB `playwright install` (issue #476).",
      sections: [
        {
          title: "One variable, nothing else moves",
          prose:
            "Playwright resolves its registry directory from `PLAYWRIGHT_BROWSERS_PATH` at runtime, so pointing that at `~/.cache/ms-playwright` — Playwright's own default on Linux, and ordinary data as far as macOS is concerned — is the whole fix. Browsers stay runtime-managed by Playwright, the same decision recorded in `pkgs/playwright-cli.nix`, and the cache stays keyed by browser build id, so every project on a matching build shares one copy. `home.sessionVariables` only reaches zsh, so the variable is set again for Nushell.",
          lines: [19, 26],
        },
      ],
    },
  },

  "home/ssh.nix": {
    about: "SSH client — GitHub key via Keychain, private hosts kept out of the repo.",
    tags: ["ssh"],
    walkthrough: {
      intro:
        "The declared SSH config holds only what's safe to publish. `enableDefaultConfig = false` stops home-manager from emitting its implicit `Host *` defaults, and `includes` pulls in untracked host definitions from `~/.ssh/config.d/` — so work servers and other machine-local hosts never land in this repository.",
      sections: [
        {
          title: "github.com",
          prose:
            "A single ed25519 key, with `IdentitiesOnly` so ssh doesn't offer every key in the agent. The key is added to the agent on first use, and `UseKeychain` stores its passphrase in the macOS Keychain.",
          lines: [17, 23],
        },
      ],
    },
  },

  "home/starship.nix": {
    about: "Starship prompt — explicit module format, Nushell integration.",
    tags: ["shell", "prompt"],
    walkthrough: {
      intro:
        "Starship is the cross-shell prompt, enabled here for Nushell. A leading newline gives every prompt breathing room, and instead of the default module list, `format` names exactly what appears.",
      sections: [
        {
          title: "Format",
          prose:
            "User, host, free disk space, directory, git branch and status, and command duration, then a line break and the `❯` character — green on success, red on failure. The user and host show even outside SSH, and the command duration only for commands that took two seconds or more.",
          lines: [33, 33],
        },
        {
          title: "Free disk space",
          prose:
            "Starship has no built-in module for disk space, so `diskFree` builds a `custom` module that runs `df -h /` and prints a hard disk glyph followed by the available space over the disk size, as in `with 󰋊 120Gi / 500Gi`. The macOS system and data volumes share one APFS container, so `/` reports the same free space as the data volume.",
          lines: [3, 19],
        },
        {
          title: "Colour by usage",
          prose:
            "A custom module can't restyle itself from its own output, so there are three of them, one per colour: cyan below 90% used, yellow from 90%, and red from 95% — the same levels as Powerlevel10k's `disk_usage`. Each one's `when` computes the used share and shows the module only inside its own range, so exactly one appears.",
          lines: [55, 60],
        },
      ],
    },
  },

  "home/vite-plus.nix": {
    about: "vp config — prefer the Nix-provided Node over vp's managed runtime.",
    tags: ["javascript", "config"],
    walkthrough: {
      intro:
        "vp ships its own Node.js version manager and defaults to managed mode, in which every command runs on a Node it downloads into `~/.local/share/vite-plus` rather than the one on `$PATH`. On this machine that's backwards: `pkgs/vite-plus.nix` already wraps vp with `nodejs_26`, and managed mode both ignores it and builds up a multi-gigabyte runtime store in `$HOME`. `shimMode = \"system_first\"` makes vp prefer the Node on `$PATH`, falling back to a managed runtime only when there is none. `vp env on` would flip that back imperatively, so it's pinned in a generated `config.json` (issue #413).",
    },
  },

  "home/vscode.nix": {
    about: "VS Code settings + keybindings synced from the vscode-settings repo.",
    tags: ["editor"],
    walkthrough: {
      intro:
        "VS Code's `settings.json` and `keybindings.json` are sourced from a separate repo (`naitokosuke/vscode-settings`), pinned via the flake input. Settings are linked as-is; the keybinding file upstream is JSONC (comments included), so it's converted to JSON at build time.",
      sections: [
        {
          title: "JSONC → JSON with jsonnet",
          prose:
            "JSONC — `//` and `/* */` comments, trailing commas — is valid Jsonnet input, and jsonnet emits plain JSON. So the conversion is a real parse: malformed input fails the build instead of being silently corrupted (issue #364).",
          lines: [9, 16],
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
    about: "Pulls in Nushell (interactive) and Zsh (login), and sets the session PATH.",
    tags: ["shell", "index"],
    walkthrough: {
      intro:
        "The shell story is dual: Nushell is the interactive shell inside Ghostty (structured-data, modern), while Zsh remains the *login* shell so VS Code extensions, SSH, and Claude Code see a familiar POSIX environment. This file imports both.",
      sections: [
        {
          title: "Session PATH",
          prose:
            "`home.sessionPath` is a session-wide option, so it's set here rather than in a shell-specific module (issue #366): `~/.nix-profile/bin` first, then `common.pathEntries` reversed, since that list runs from lowest to highest priority while `sessionPath` runs the other way. Zsh picks it up in `.zprofile`; Nushell builds its own `$PATH` from the same list in `nushell.nix`.",
          lines: [20, 26],
        },
      ],
    },
  },

  "home/shell/common.nix": {
    about: "Shared shell config — PATH, env vars, aliases, Homebrew-forbidden formulae.",
    tags: ["shell", "common"],
    walkthrough: {
      intro:
        "Anything that should be identical in Nushell and Zsh — `$PATH` ordering, environment variables, aliases — lives here. It isn't a module but a plain function of `username` returning an attrset, which `nushell.nix` and `zsh.nix` each import and render in their own syntax. It also defines a `homebrewForbiddenFormulae` list (`bun`, `claude`, `node`, …), exported as `HOMEBREW_FORBIDDEN_FORMULAE`, so `brew install` can never shadow a Nix-managed binary on `$PATH`.",
      sections: [
        {
          title: "PATH entries",
          prose:
            "Listed from lowest to highest priority: each shell prepends them in order, so the Nix profiles end up ahead of Homebrew and `/usr/local/bin`.",
          lines: [50, 61],
        },
      ],
    },
  },

  "home/shell/nushell.nix": {
    about: "Nushell — interactive shell inside Ghostty.",
    tags: ["shell"],
    walkthrough: {
      intro:
        "Nushell is the interactive shell. Unlike POSIX shells, every command's output is structured data, which is a much better fit for the kinds of data-shaped pipelines this dotfiles repo encourages. Some IDE integrations still need POSIX, which is why Zsh sticks around as the login shell.",
      sections: [
        {
          title: "Environment",
          prose:
            "Aliases and environment variables come from `common.nix`. `env.nu` splits `$PATH` into a list, then `path add`s each common entry and `~/.nix-profile/bin` on top.",
          lines: [25, 46],
        },
        {
          title: "Completions and helpers",
          prose:
            "Completions for git, gh, nix, pnpm, and rg come from the pinned `nu_scripts` input. `mkcd` makes a directory and enters it, and `cpwd` copies the current directory to the clipboard — a command rather than an alias, because Nushell aliases can't contain pipelines. A new terminal starts in `~/src/github.com/<user>` unless it was opened by VS Code.",
          lines: [49, 74],
        },
      ],
    },
  },

  "home/shell/zsh.nix": {
    about: "Zsh — login shell for VS Code extensions, SSH, and Claude Code.",
    tags: ["shell"],
    walkthrough: {
      intro:
        "Zsh handles login-shell responsibilities — anything that spawns a non-interactive shell to read `$PATH` and environment variables sees Zsh, not Nushell. `$PATH` comes from `home.sessionPath` in `shell/default.nix`, so this module only adds the shared environment variables and aliases from `common.nix`, plus `cl` and `cpwd` (`pwd | pbcopy`, which copies the current directory to the clipboard).",
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
