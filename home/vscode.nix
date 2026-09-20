{
  inputs,
  lib,
  pkgs,
  ...
}:

let
  # keybinding.jsonc → spec-compliant JSON, converted at build time.
  # JSONC (// and /* */ comments, trailing commas) is valid Jsonnet input
  # and jsonnet emits plain JSON, so this is a real parse — invalid input
  # fails the build instead of silently corrupting the output the way the
  # previous regex-based conversion could (issue #364).
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
