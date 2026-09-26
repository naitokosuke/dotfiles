{
  config,
  lib,
  ...
}:

{
  imports = [
    ./nushell.nix
    ./zsh.nix
  ];

  # sessionPath is session-wide, so it lives here rather than in a
  # shell-specific module (issue #366).
  # pathEntries is low-to-high priority; sessionPath is high-to-low, so reverse
  home.sessionPath = lib.reverseList config.naitokosuke.shell.pathEntries;
}
