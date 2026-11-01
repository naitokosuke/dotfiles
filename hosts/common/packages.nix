{ pkgs, ... }:

let
  # darwin-rebuild rejects --log-format and Lix doesn't expose it as a setting,
  # so use nom in its default (non-JSON) mode which parses bare nix output.
  darwin-rebuild-nom = pkgs.writeShellApplication {
    name = "darwin-rebuild-nom";
    runtimeInputs = [ pkgs.nix-output-monitor ];
    text = ''
      darwin-rebuild "$@" 2>&1 | nom
    '';
  };
in
{
  environment.systemPackages = with pkgs; [
    agent-browser
    bun
    cargo-deny
    naitokosuke.cclens
    darwin-rebuild-nom
    devenv
    fd
    naitokosuke.frog
    fzf
    gh
    ghq
    git
    gomi
    gwq
    herdr
    idris2
    nixd
    nix-output-monitor
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
