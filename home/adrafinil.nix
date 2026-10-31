# Adrafinil (cask in hosts/common/homebrew.nix) keeps the Mac awake for
# agents: ./claude.nix declares its hooks and ./mcp.nix its MCP server, and
# both run the CLI inside the app bundle. That path cannot come from the
# store, so it is declared once here and tied to the cask that installs it:
# drop the cask and evaluation fails, instead of the hooks silently doing
# nothing and the server entry pointing at nothing. The bundle path is used
# instead of /usr/local/bin/adrafinil, which the app only creates
# asynchronously at launch.
{
  lib,
  osConfig,
  ...
}:

{
  options.naitokosuke.adrafinilCli = lib.mkOption {
    type = lib.types.str;
    readOnly = true;
    default = "/Applications/Adrafinil.app/Contents/Helpers/adrafinil";
    description = "Path to the Adrafinil CLI inside the app bundle that the adrafinil cask installs.";
  };

  # nix-darwin normalises homebrew.casks into submodules, so the names are read
  # off `name` rather than the list itself.
  config.assertions = [
    {
      assertion = lib.any (declared: declared.name == "adrafinil") osConfig.homebrew.casks;
      message = "home/adrafinil.nix: ./claude.nix and ./mcp.nix run the Adrafinil CLI, which the adrafinil cask provides, but that cask is not in hosts/common/homebrew.nix.";
    }
  ];
}
