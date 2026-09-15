# Shell configurations aggregator
#
# Manages both Nushell (interactive terminal) and Zsh (login shell for IDE/CLI tools).
# Common settings (PATH, env vars, aliases) are defined in common.nix.
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

  # PATH configuration via home-manager's sessionPath. It is a session-wide
  # option, so it lives here rather than in a shell-specific module (issue #366).
  # common.pathEntries is low-to-high priority; sessionPath is high-to-low, so reverse
  home.sessionPath = [
    "${config.home.homeDirectory}/.nix-profile/bin"
  ]
  ++ lib.reverseList common.pathEntries;
}
