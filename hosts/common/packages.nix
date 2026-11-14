{ pkgs, ... }:

{
  # gh and git are installed by home-manager (home/gh.nix, home/git.nix), and
  # rebuilds go through nh (home/nh.nix), which renders nom output itself.
  environment.systemPackages = with pkgs; [
    agent-browser
    bun
    cargo-deny
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
    rustup
    sd
    tree
    uv
    vim
    naitokosuke.vite-plus
  ];
}
