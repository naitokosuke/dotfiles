{ pkgs, ... }:

let
  # darwin-rebuild output piped through nix-output-monitor for richer build progress.
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
    ax
    bun
    # Moved from an undeclared brew formula when homebrew went fully
    # declarative (issue #363)
    cargo-deny
    llm-agents.claude-code
    darwin-rebuild-nom
    devenv
    fd
    frog
    fzf
    gh
    ghq
    git
    gomi
    gwq
    herdr
    idris2
    ni
    nixd
    nix-output-monitor
    nodejs_26
    octorus
    oxfmt
    playwright-cli
    pnpm
    ripgrep
    rustup
    sd
    tree
    uv
    vim
    vite-plus
    vize
  ];
}
