{
  config,
  lib,
  ...
}:

let
  common = import ./common.nix { inherit (config.naitokosuke) username; };
in
{
  imports = [
    ./nushell.nix
    ./zsh.nix
  ];

  # sessionPath is session-wide, so it lives here rather than in a
  # shell-specific module (issue #366).
  # common.pathEntries is low-to-high priority; sessionPath is high-to-low, so reverse
  home.sessionPath = [
    "${config.home.homeDirectory}/.nix-profile/bin"
  ]
  ++ lib.reverseList common.pathEntries;
}
