{ pkgs, ... }:

{
  # gh and git are installed by home-manager (home/gh.nix, home/git.nix), and
  # rebuilds go through nh (home/nh.nix), which renders nom output itself.
  #
  # Only tools that are used outside any project belong here; a project pins
  # its own toolchain in a devShell or devenv (#550). The language tools that
  # stay are the ones used without a project: nodejs_26 runs `vp`
  # (pkgs/vite-plus.nix), bun and pnpm run one-off scripts and the many
  # JavaScript checkouts that have no shell of their own, uv runs one-off
  # Python tools, and idris2 is for exercises.
  environment.systemPackages = with pkgs; [
    agent-browser
    bun
    naitokosuke.cclens
    devenv
    fd
    naitokosuke.frog
    fzf
    ghq
    gomi
    gwq
    herdr
    idris2
    nixd
    nodejs_26
    oxfmt
    naitokosuke.playwright-cli
    pnpm
    ripgrep
    sd
    tree
    uv
    vim
    naitokosuke.vite-plus
  ];
}
