# gh extension for creating and listing GitHub sub-issues, registered by
# home/gh.nix. programs.gh.extensions links this package's bin/ under
# ~/.local/share/gh/extensions/<pname>, so pname and the binary name must
# both be "gh-sub-issue".
{
  lib,
  stdenvNoCC,
  versionCheckHook,
  sources,
}:

stdenvNoCC.mkDerivation {
  pname = "gh-sub-issue";
  version = sources.gh-sub-issue.version;
  src = sources.gh-sub-issue.src;

  dontUnpack = true;

  ## Install
  # The release asset is a bare executable, so there is nothing to unpack.
  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/gh-sub-issue
    runHook postInstall
  '';

  ## Install check
  # `versionCheckHook` runs `gh-sub-issue --version` and expects `version` in
  # the output, so a binary that does not run, or belongs to a different
  # release than nvfetcher pinned, fails the build instead of surfacing as a
  # broken gh extension.
  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  meta = {
    description = "gh extension for creating and listing GitHub sub-issues";
    homepage = "https://github.com/yahsan2/gh-sub-issue";
    changelog = "https://github.com/yahsan2/gh-sub-issue/releases/tag/v${sources.gh-sub-issue.version}";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "gh-sub-issue";
    platforms = [ "aarch64-darwin" ];
  };
}
