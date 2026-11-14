{
  inputs,
  lib,
  pkgs,
  ...
}:

let
  # keybinding.jsonc → JSON at build time. JSONC is valid Jsonnet input, so
  # this is a real parse: invalid input fails the build (#364).
  keybindings-json = pkgs.runCommand "keybindings.json" { } ''
    ${lib.getExe' pkgs.jsonnet "jsonnet"} ${inputs.vscode-settings}/keybinding.jsonc -o $out
  '';
in
{
  # From nixpkgs rather than a cask, so the `code` the plan hook in
  # ./claude.nix runs is a store path (#556).
  home.packages = [ pkgs.vscode ];

  home.file = {
    "Library/Application Support/Code/User/settings.json".source =
      "${inputs.vscode-settings}/.vscode/settings.json";

    "Library/Application Support/Code/User/keybindings.json".source = keybindings-json;
  };
}
