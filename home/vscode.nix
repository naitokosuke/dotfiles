# VS Code's settings and keybindings, from the pinned vscode-settings input.
# The editor itself is a cask.
{
  inputs,
  lib,
  pkgs,
  ...
}:

let
  ## JSONC to JSON with jsonnet
  # keybinding.jsonc → JSON at build time. JSONC is valid Jsonnet input, so
  # this is a real parse: invalid input fails the build (#364).
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
