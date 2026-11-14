# GUI apps are Homebrew casks (hosts/common/homebrew.nix), so a binary that
# comes with one cannot be referenced by store path. A module that runs such a
# binary names the cask here, and evaluation fails when the cask is dropped,
# instead of the binary silently going missing at runtime.
{
  config,
  lib,
  osConfig,
  ...
}:

{
  options.naitokosuke.requiredCasks = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = { };
    example = {
      visual-studio-code = "home/claude.nix runs `code` in its plan hook";
    };
    description = "Homebrew casks that home-manager modules depend on, each with the reason.";
  };

  # nix-darwin normalises homebrew.casks into submodules, so the names are read
  # off `name` rather than the list itself.
  config.assertions = lib.mapAttrsToList (cask: reason: {
    assertion = lib.any (declared: declared.name == cask) osConfig.homebrew.casks;
    message = "${reason}, which the ${cask} cask provides, but that cask is not in hosts/common/homebrew.nix.";
  }) config.naitokosuke.requiredCasks;
}
