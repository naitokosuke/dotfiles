# TODO: Once official nixpkgs support (NixOS/nixpkgs#490230) is merged,
# switch to pkgs.playwright-cli and delete this file and the nvfetcher entry.
#
# Unlike the other packages here, this is a source build: @playwright/cli is
# distributed only on npm, with no prebuilt release binaries, so nvfetcher
# pins the GitHub source tree and buildNpmPackage installs it.
{
  lib,
  buildNpmPackage,
  importNpmLock,
  versionCheckHook,
  sources,
}:

buildNpmPackage {
  pname = "playwright-cli";
  version = lib.removePrefix "v" sources.playwright-cli.version;
  src = sources.playwright-cli.src;

  ## Dependencies from the upstream lockfile
  # `importNpmLock` builds the dependencies from the upstream package.json and
  # package-lock.json, so there is no npmDepsHash to update after a bump
  # (#411). nvfetcher copies both files out of the source into pkgs/_sources
  # on every bump (`extract` in nvfetcher.toml), so they are read from the
  # repository: reading them out of `src` would be import-from-derivation
  # (#546).
  npmDeps = importNpmLock {
    package = lib.importJSON sources.playwright-cli.extract."package.json";
    packageLock = lib.importJSON sources.playwright-cli.extract."package-lock.json";
  };
  npmConfigHook = importNpmLock.npmConfigHook;

  dontNpmBuild = true;

  ## Browsers stay runtime-managed
  # Browsers are left to Playwright's own cache (home/playwright.nix says
  # where). Pinning nixpkgs' playwright-driver.browsers would mismatch the
  # vendored Playwright, which tracks alpha releases ahead of nixpkgs.

  ## Install check
  # `versionCheckHook` runs `playwright-cli --version` and expects `version` in
  # the output, so the installed entry point is known to start before it lands
  # on PATH.
  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  meta = {
    description = "Playwright CLI for browser automation";
    homepage = "https://github.com/microsoft/playwright-cli";
    changelog = "https://github.com/microsoft/playwright-cli/releases/tag/${sources.playwright-cli.version}";
    license = lib.licenses.asl20;
    mainProgram = "playwright-cli";
  };
}
