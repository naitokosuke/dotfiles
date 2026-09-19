# TODO: Once official nixpkgs support (NixOS/nixpkgs#490230) is merged,
# switch to pkgs.playwright-cli and delete this file and the nvfetcher entry.
#
# Unlike the other packages here, this is a source build: @playwright/cli is
# distributed only on npm, with no prebuilt release binaries.
{
  lib,
  buildNpmPackage,
  importNpmLock,
  sources,
}:

let
  # Bound here because importNpmLock has to read the lockfile out of the very
  # same source tree the derivation builds.
  src = sources.playwright-cli.src;
in
buildNpmPackage {
  pname = "playwright-cli";
  version = lib.removePrefix "v" sources.playwright-cli.version;
  inherit src;

  # node_modules comes straight from the upstream package-lock.json, so there
  # is no dependency hash to keep in sync with nvfetcher's version bumps.
  npmDeps = importNpmLock { npmRoot = src; };
  npmConfigHook = importNpmLock.npmConfigHook;

  dontNpmBuild = true;

  # Browsers stay runtime-managed in Playwright's own cache. Pinning
  # nixpkgs' playwright-driver.browsers would mismatch the vendored
  # Playwright, which tracks alpha releases ahead of nixpkgs.

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    $out/bin/playwright-cli --version > /dev/null
    runHook postInstallCheck
  '';

  meta = {
    description = "Playwright CLI for browser automation";
    homepage = "https://github.com/microsoft/playwright-cli";
    changelog = "https://github.com/microsoft/playwright-cli/releases/tag/${sources.playwright-cli.version}";
    license = lib.licenses.asl20;
    mainProgram = "playwright-cli";
  };
}
