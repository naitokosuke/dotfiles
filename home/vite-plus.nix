# vp defaults to "managed" mode, where it downloads its own Node into
# ~/.local/share/vite-plus and ignores the one pkgs/vite-plus.nix wraps it
# with. system_first makes vp prefer the Node on PATH. `vp env on` would flip
# it back imperatively, so it is pinned here (#413).
{ pkgs, ... }:

let
  jsonFormat = pkgs.formats.json { };
in
{
  xdg.configFile."vite-plus/config.json".source = jsonFormat.generate "vite-plus-config.json" {
    shimMode = "system_first";
  };
}
