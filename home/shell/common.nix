{ username }:

{
  # Packages managed by Nix - prevent accidental brew install
  # See: https://github.com/Homebrew/brew/issues/19939
  homebrewForbiddenFormulae = [
    "bun"
    "claude"
    "deno"
    "fd"
    "fzf"
    "gh"
    "git"
    "node"
    "npm"
    "pip"
    "pnpm"
    "python"
    "python3"
    "ripgrep"
    "vim"
    "yarn"
  ];

  envVars = {
    EDITOR = "vim";
  };

  # POSIX-compatible syntax only: shared by Nushell and Zsh
  aliases = {
    l = "ls";
    la = "ls -la";
    ll = "ls -l";
    ":q" = "exit";
    nid = "ni -D";
  };

  # PATH entries in priority order (last = highest priority)
  # Each shell prepends these in order, so the last entry ends up first in $PATH
  pathEntries = [
    "/usr/local/bin"
    "/opt/homebrew/sbin"
    "/opt/homebrew/bin"
    "/nix/var/nix/profiles/default/bin"
    "/run/current-system/sw/bin"
    "/etc/profiles/per-user/${username}/bin"
    # Note: $HOME/.nix-profile/bin is handled separately in each shell
    # because of different variable expansion syntax
  ];
}
