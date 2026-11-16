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

  ## Background image
  # VS Code has no setting for a background image, so the script patches the
  # workbench CSS inside the app bundle. A VS Code update reverts it, and the
  # next switch applies it again. macOS App Management blocks writes to the
  # bundle unless the terminal running the switch is allowed under
  # System Settings > Privacy & Security > App Management, so a failure only
  # warns instead of failing activation.
  home.activation.vscodeBackground = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    PATH=${lib.makeBinPath [ pkgs.perl ]}:$PATH \
      run ${lib.getExe pkgs.bash} ${inputs.vscode-settings}/scripts/vscode-background.sh apply \
      || warnEcho "VS Code background was not applied. Allow your terminal under App Management and switch again."
  '';
}
