# MCP servers reach Claude Code through mcp-servers-nix's home-manager module
# (hosts/common/home-manager.nix): `programs.mcp` collects them and
# `enableMcpIntegration` hands them over. The servers themselves are declared
# by the modules that own them (see ./adrafinil.nix).
{
  programs.mcp.enable = true;

  programs.claude-code.enableMcpIntegration = true;
}
