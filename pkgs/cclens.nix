{
  lib,
  stdenvNoCC,
  versionCheckHook,
  sources,
}:

stdenvNoCC.mkDerivation {
  pname = "cclens";
  version = lib.removePrefix "v" sources.cclens-darwin-arm64.version;
  src = sources.cclens-darwin-arm64.src;

  # The tarball has no top-level directory — the `cclens` binary sits at the root.
  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    install -Dm755 cclens $out/bin/cclens
    runHook postInstall
  '';

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  meta = {
    description = "Lens onto your Claude Code usage: finds wasted time, tokens and effort in transcripts and config";
    homepage = "https://github.com/lambdalisue/cclens";
    changelog = "https://github.com/lambdalisue/cclens/releases/tag/${sources.cclens-darwin-arm64.version}";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "cclens";
    platforms = [ "aarch64-darwin" ];
  };
}
