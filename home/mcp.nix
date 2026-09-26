{
  lib,
  osConfig,
  ...
}:

{
  mcp-servers.settings.servers = {
    # Adrafinil's `keep_awake` tool, so an agent can hold the Mac awake for
    # work that outlives its turn (e.g. background shells), which the hooks in
    # ./claude.nix do not cover. Same entry upstream's installer writes to
    # ~/.claude.json, pointing at the in-bundle CLI of the adrafinil cask.
    # Adrafinil only inspects ~/.claude.json, so its Settings → Agents tab
    # still reports the MCP server as not installed.
    #
    # The path is out of the store by necessity, so it is tied to the cask that
    # installs it: removing the cask fails evaluation rather than leaving a
    # server entry pointing at nothing.
    adrafinil = {
      command =
        lib.throwIfNot (lib.any (declared: declared.name == "adrafinil") osConfig.homebrew.casks)
          "home/mcp.nix declares Adrafinil's MCP server, but the adrafinil cask is not in hosts/common/homebrew.nix."
          "/Applications/Adrafinil.app/Contents/Helpers/adrafinil";
      args = [
        "mcp"
        "--tool"
        "claude-code"
      ];
    };
  };

  programs.mcp.enable = true;

  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;
  };
}
