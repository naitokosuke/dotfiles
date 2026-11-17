# fxtwitter: a CLI for the FxTwitter API that prints posts, profiles and
# search results as JSON (#628). Like playwright-cli, it is published only on
# npm, so nvfetcher pins the GitHub source tree and buildNpmPackage builds it.
{
  lib,
  buildNpmPackage,
  importNpmLock,
  sources,
}:

buildNpmPackage {
  pname = "fxtwitter";
  version = lib.removePrefix "v" sources.fxtwitter.version;
  src = sources.fxtwitter.src;

  ## Dependencies from the upstream lockfile
  # Read from the copies nvfetcher extracts into pkgs/_sources, as in
  # ./playwright-cli.nix, so there is no npmDepsHash to update after a bump.
  npmDeps = importNpmLock {
    package = lib.importJSON sources.fxtwitter.extract."package.json";
    packageLock = lib.importJSON sources.fxtwitter.extract."package-lock.json";
  };
  npmConfigHook = importNpmLock.npmConfigHook;

  # dist/ is not committed upstream; `npm run build` (tsdown) produces it.
  # The CLI has no --version flag, so there is no versionCheckHook.

  meta = {
    description = "Typed wrapper and CLI for the FxTwitter API";
    homepage = "https://github.com/otnc/fxtwitter-wrapper";
    changelog = "https://github.com/otnc/fxtwitter-wrapper/releases/tag/${sources.fxtwitter.version}";
    license = lib.licenses.mit;
    mainProgram = "fxtwitter";
  };
}
