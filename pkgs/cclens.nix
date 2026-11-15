# cclens analyses Claude Code transcripts and config for wasted time, tokens
# and effort. Installed from the release archive (see ./default.nix).
{
  lib,
  stdenvNoCC,
  versionCheckHook,
  sources,
}:

stdenvNoCC.mkDerivation {
  pname = "cclens";
  version = lib.removePrefix "v" sources.cclens.version;
  src = sources.cclens.src;

  ## Install
  # The tarball has no top-level directory: the `cclens` binary sits at the
  # root, so `sourceRoot` is the unpack directory itself.
  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    install -Dm755 cclens $out/bin/cclens
    runHook postInstall
  '';

  ## Install check
  # `versionCheckHook` runs `cclens --version` and expects `version` in the
  # output, the same check the other binary packages here use.
  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  meta = {
    description = "Lens onto your Claude Code usage: finds wasted time, tokens and effort in transcripts and config";
    homepage = "https://github.com/lambdalisue/cclens";
    changelog = "https://github.com/lambdalisue/cclens/releases/tag/${sources.cclens.version}";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "cclens";
    platforms = [ "aarch64-darwin" ];
  };
}
