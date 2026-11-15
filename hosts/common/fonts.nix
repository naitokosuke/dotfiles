# Input Mono, the editor font VS Code is set to (#569). It is unfree, so
# flake.nix allows it by name.
{ pkgs, ... }:

{
  fonts.packages = [ pkgs.input-fonts ];
}
