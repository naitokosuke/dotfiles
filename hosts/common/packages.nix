# The system CLI toolbelt, on PATH for every user and login shell, from
# nixpkgs and from the nvfetcher-tracked set in ../../pkgs as `naitokosuke.*`.
# gh and git are installed by home-manager (home/gh.nix, home/git.nix), and
# rebuilds go through nh (home/nh.nix), which renders nom output itself.
{ pkgs, ... }:

{
  ## What belongs here
  # Only tools that are used outside any project; a project pins its own
  # toolchain in a devShell or devenv (#550). The language tools that stay are
  # the ones used without a project: nodejs_26 runs `vp` (pkgs/vite-plus.nix),
  # bun and pnpm run one-off scripts and the many JavaScript checkouts that
  # have no shell of their own, uv runs one-off Python tools, and idris2 is
  # for exercises. Claude Code is deliberately absent: the only `claude` on
  # PATH is the sandboxed one from home/claude-sandbox.nix.
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
