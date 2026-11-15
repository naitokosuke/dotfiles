# Input, the font the VS Code settings use for the editor (#569).
{ pkgs, ... }:

{
  fonts.packages = [ pkgs.input-fonts ];
}
