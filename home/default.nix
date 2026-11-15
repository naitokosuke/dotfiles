# The user layer: one module per tool, composed as a flat list, so opening
# git.nix shows the whole git story and claude.nix the Claude Code settings,
# with its deletion guard and sandbox in siblings of their own.
# `home.username` and `home.homeDirectory` are not set here: home-manager
# derives them from users.users, which hosts/common/home-manager.nix fills
# from `config.naitokosuke`.
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
    ./required-casks.nix
    ./ssh.nix
    ./starship.nix
    ./vite-plus.nix
    ./vscode.nix
    ./zoxide.nix
    ./zsh.nix
  ];

  ## State version
  # The home-manager release this configuration was first written for. Its
  # migrations key off it, so it is not bumped casually.
  home.stateVersion = "25.05";
}
