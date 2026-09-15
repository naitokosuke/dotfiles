# MCP (Model Context Protocol) server configuration
#
# Uses natsukium/mcp-servers-nix (via home-manager sharedModules) as the
# central registry, and lets programs.claude-code consume servers declaratively.
#
# https://github.com/natsukium/mcp-servers-nix
{ lib, pkgs, ... }:

{
  mcp-servers.settings.servers = {
    # Chrome DevTools MCP — not covered by mcp-servers-nix's built-in modules,
    # declared via the freeform `settings.servers` escape hatch. The server
    # itself is the Nix-packaged pkgs.chrome-devtools-mcp (./pkgs), not an
    # `npx -y ...@latest` fetched from the registry at launch time.
    # https://github.com/ChromeDevTools/chrome-devtools-mcp
    chrome-devtools = {
      command = lib.getExe pkgs.chrome-devtools-mcp;
    };

    # Adrafinil's `keep_awake` tool, so an agent can hold the Mac awake for
    # work that outlives its turn (e.g. background shells), which the hooks in
    # ./claude.nix do not cover. Same entry upstream's installer writes to
    # ~/.claude.json, pointing at the in-bundle CLI of the adrafinil cask.
    # Adrafinil only inspects ~/.claude.json, so its Settings → Agents tab
    # still reports the MCP server as not installed.
    adrafinil = {
      command = "/Applications/Adrafinil.app/Contents/Helpers/adrafinil";
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
