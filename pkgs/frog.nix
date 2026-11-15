# frog logs the friction coding agents run into. The release is a single
# gzipped binary rather than an archive.
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

  ## Fetch and install
  # Nothing to unpack: the binary is decompressed straight into $out/bin.
  dontUnpack = true;
  installPhase = ''
    runHook preInstall
    install -d $out/bin
    gunzip -c $src > $out/bin/frog
    chmod 755 $out/bin/frog
    runHook postInstall
  '';

  ## Install check
  # `frog --version` has to print the version nvfetcher pinned.
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
