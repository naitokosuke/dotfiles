# gh extension: programs.gh.extensions links this package's bin/ under
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
  version = sources.gh-sub-issue-darwin-arm64.version;
  src = sources.gh-sub-issue-darwin-arm64.src;

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/gh-sub-issue
    runHook postInstall
  '';

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  meta = {
    description = "gh extension for creating and listing GitHub sub-issues";
    homepage = "https://github.com/yahsan2/gh-sub-issue";
    changelog = "https://github.com/yahsan2/gh-sub-issue/releases/tag/v${sources.gh-sub-issue-darwin-arm64.version}";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "gh-sub-issue";
    platforms = [ "aarch64-darwin" ];
  };
}
