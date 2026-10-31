{ ... }:

{
  imports = [
    ./adrafinil.nix
    ./atuin.nix
    ./claude-rm-guard
    ./claude-sandbox.nix
    ./claude.nix
    ./direnv.nix
    ./gh.nix
    ./ghostty.nix
    ./git.nix
    ./gomi.nix
    ./gwq.nix
    ./mcp.nix
    ./nh.nix
    ./playwright.nix
    ./ssh.nix
    ./starship.nix
    ./vite-plus.nix
    ./vscode.nix
    ./zoxide.nix
    ./zsh.nix
  ];

  home.stateVersion = "25.05";
}
