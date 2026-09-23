# TODO: Once official nixpkgs support (NixOS/nixpkgs#533925) is merged, switch
# to pkgs.vite-plus and delete this file, pkgs/vite-plus-runtime and the
# nvfetcher entry.
#
# `vp` is only the Rust launcher. Every subcommand that does real work (dev,
# build, test, check, lint, fmt, create, migrate, ...) is handed to a
# JavaScript toolchain that vp resolves at <prefix>/node_modules/vite-plus,
# relative to the resolved path of the executable. Installing the launcher on
# its own leaves all of them dying with "Cannot find module" (issue #413), so
# the npm dependency tree is built here and installed next to it.
#
# The approach is taken from https://github.com/ryoppippi/nix-vite-plus, which
# worked this out first and documents the parts that are not obvious until you
# hit them. Deviations from it are noted where they occur.
{
  lib,
  stdenvNoCC,
  importNpmLock,
  makeWrapper,
  nodejs_26,
  sources,
}:

let
  inherit (sources.vite-plus-darwin-arm64) version;

  # Kept in step with the system Node in hosts/common/packages.nix, so the
  # toolchain does not drag a second Node into the closure.
  nodejs = nodejs_26;

  runtime = ./vite-plus-runtime;

  lockedVersion =
    (lib.importJSON (runtime + "/package-lock.json")).packages."node_modules/vite-plus".version;

  nodeModules = importNpmLock.buildNodeModules {
    npmRoot = runtime;
    inherit nodejs;

    derivationArgs = {
      pname = "vite-plus-runtime";
      inherit version;

      postInstall = ''
        # `vp create` copies templates straight out of the store, so without
        # this the scaffolded project inherits store permissions and lands
        # unwritable.
        chmod -R u+w $out/node_modules/vite-plus/dist/create
        substituteInPlace $out/node_modules/vite-plus/dist/create/bin.js \
          --replace-fail \
            'else fs.copyFileSync(src, dest);' \
            'else { fs.copyFileSync(src, dest); fs.chmodSync(dest, 0o644); }'

        # vp reaches the toolchain by path and never through node_modules/.bin,
        # which would only put a second oxlint/oxfmt on PATH.
        rm -rf $out/node_modules/.bin

        # npm's own bookkeeping copy of the lockfile still carries the rewritten
        # `file:` sources importNpmLock pointed at the store, which keeps every
        # dependency tarball alive in the runtime closure — around 300 MB of
        # sources for a toolchain that is 144 MB extracted. Nothing reads it at
        # runtime.
        rm -f $out/node_modules/.package-lock.json
      '';
    };
  };
in
# The launcher and the toolchain are two halves of one release and must not
# drift apart. nvfetcher bumps the launcher on its own and never touches the
# lockfile, so without this a `chore: update nvfetcher sources` PR would
# quietly restore the very breakage this package exists to fix — the same class
# of drift as #411, caught at eval time instead of at runtime. (nix-vite-plus
# keeps both in step from one update script; here the two update paths are
# separate, so this fails loudly rather than silently.)
lib.throwIf (lockedVersion != version)
  ''
    vite-plus: the launcher is at ${version}, but pkgs/vite-plus-runtime pins vite-plus ${lockedVersion}.
    Regenerate the lockfile to match:
      cd pkgs/vite-plus-runtime
      npm pkg set dependencies.vite-plus=${version}
      rm -f package-lock.json
      npm install --package-lock-only --ignore-scripts

    The old lockfile has to go first: vite-plus lists oxlint, oxfmt and vitest
    as peers of itself, and npm gives up with ERESOLVE rather than migrate that
    tree across a bump.
  ''
  (
    stdenvNoCC.mkDerivation {
      pname = "vite-plus";
      inherit version;
      src = sources.vite-plus-darwin-arm64.src;

      # The npm tarball keeps everything under a single `package/` directory.
      sourceRoot = "package";

      nativeBuildInputs = [ makeWrapper ];

      installPhase = ''
        runHook preInstall

        install -Dm755 vp $out/bin/vp

        # Symlinked rather than copied: node follows it transparently and the
        # toolchain stays a single copy in the store.
        ln -s ${nodeModules}/node_modules $out/node_modules

        # The JavaScript half needs a node to run on whatever the caller has on
        # PATH. vp dispatches on argv[0], which makeWrapper preserves with
        # `exec -a "$0"`, so the aliases below still work through the wrapper.
        wrapProgram $out/bin/vp --prefix PATH : ${lib.makeBinPath [ nodejs ]}

        # Provide the standalone aliases the official installer creates via
        # `vp env setup`: vp is a multi-call binary dispatching on argv[0]
        # (vpr -> `vp run`, vpx -> `vp dlx`). The node/npm/npx/corepack shims
        # it also creates are deliberately omitted — they belong to the
        # opt-out-able Node version manager and would conflict with Nix-managed Node.
        ln -s vp $out/bin/vpr
        ln -s vp $out/bin/vpx

        # Since 0.3.2 vp installs itself on first start unless this marker sits
        # next to the resolved executable (issue #434). Without it the first run
        # downloads a second, unmanaged copy of vite-plus into the Vite+ home and
        # appends to ~/.zshenv — and in the sandbox it dies on an interactive
        # prompt instead. wrapProgram moved the binary to .vp-wrapped, which is
        # still in this directory, so the marker is found through the wrapper.
        touch $out/bin/.vp-setup-complete

        runHook postInstall
      '';

      doInstallCheck = true;

      # Runs from a directory with no project-local vite-plus, which is exactly
      # where the launcher-only build used to fail. `--version` alone would not
      # catch it: it is served by the launcher and passed even while every
      # JavaScript subcommand was broken.
      installCheckPhase = ''
        runHook preInstallCheck
        checkdir=$(mktemp -d)
        checkhome=$(mktemp -d)
        # Mirrors home/vite-plus.nix. Without it vp falls back to managed mode
        # and downloads its own Node into $HOME, which is not how it runs on a
        # configured machine.
        mkdir -p "$checkhome/.config/vite-plus"
        echo '{"shimMode":"system_first"}' > "$checkhome/.config/vite-plus/config.json"
        before=$(cd "$checkhome" && find . | sort)
        # Deliberately no .node-version. Pinning one sends vp off to its own
        # managed Node instead of the one wrapProgram put on PATH, and in the
        # sandbox that fails outright with "Failed to download Node.js runtime".
        ( cd "$checkdir" && HOME="$checkhome" $out/bin/vp fmt --help ) > /dev/null
        # A store-installed vp must never set itself up again in $HOME. If
        # upstream changes how self-setup is skipped, fail here rather than
        # write into the user's home on first use.
        after=$(cd "$checkhome" && find . | sort)
        if [ "$before" != "$after" ]; then
          echo "vp wrote into HOME:" >&2
          echo "$after" >&2
          exit 1
        fi
        runHook postInstallCheck
      '';

      meta = {
        description = "Unified toolchain for JavaScript";
        homepage = "https://viteplus.dev";
        changelog = "https://github.com/voidzero-dev/vite-plus/releases/tag/v${version}";
        license = lib.licenses.mit;
        sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
        mainProgram = "vp";
        platforms = [ "aarch64-darwin" ];
      };
    }
  )
