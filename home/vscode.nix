# settings.json and keybindings.json come from naitokosuke/vscode-settings,
# pinned as a flake input, so a change there arrives with
# `nix flake update vscode-settings`. The editor itself is a cask
# (hosts/common/homebrew.nix).
{
  inputs,
  lib,
  pkgs,
  ...
}:

let
  ## JSONC to JSON
  # keybinding.jsonc upstream has comments and trailing commas, which VS Code
  # reads but nothing else does. JSONC is valid Jsonnet input, so this is a
  # real parse at build time: invalid input fails the build instead of being
  # silently corrupted (#364).
  keybindings-json = pkgs.runCommand "keybindings.json" { } ''
    ${lib.getExe' pkgs.jsonnet "jsonnet"} ${inputs.vscode-settings}/keybinding.jsonc -o $out
  '';
in
{
  home.file = {
    "Library/Application Support/Code/User/settings.json".source =
      "${inputs.vscode-settings}/.vscode/settings.json";

    "Library/Application Support/Code/User/keybindings.json".source = keybindings-json;
  };
}
