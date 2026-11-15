# frog records the friction coding agents run into, for review later (see
# AGENTS.md). Upstream releases a gzipped single binary rather than an
# archive, so the derivation decompresses it itself.
{
  lib,
  stdenvNoCC,
  versionCheckHook,
  sources,
}:

stdenvNoCC.mkDerivation {
  pname = "frog";
  version = sources.frog.version;
  src = sources.frog.src;

  dontUnpack = true;

  ## Install
  # The asset is a single gzipped file, not an archive: `dontUnpack` skips the
  # unpack phase, and the source is gunzipped straight into $out/bin.
  installPhase = ''
    runHook preInstall
    install -d $out/bin
    gunzip -c $src > $out/bin/frog
    chmod 755 $out/bin/frog
    runHook postInstall
  '';

  ## Install check
  # `versionCheckHook` runs `frog --version` and expects the derivation's
  # `version` in the output: the binary runs on this platform and is the
  # release nvfetcher pinned.
  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  meta = {
    description = "Automated friction logging for agents";
    homepage = "https://frog.fm";
    changelog = "https://github.com/wevm/frog/releases/tag/frog@${sources.frog.version}";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "frog";
    platforms = [ "aarch64-darwin" ];
  };
}
