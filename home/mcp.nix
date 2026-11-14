# The servers themselves are declared by the modules that own them (see
# ./adrafinil.nix).
{
  programs.mcp.enable = true;

  programs.claude-code.enableMcpIntegration = true;
}
