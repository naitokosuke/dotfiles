# The user layer: one module per tool, all imported here.
{
  ## Tool modules
  # One file or directory per tool, so each concern stays in one place.
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
  # The release this configuration was first written for; it changes state
  # layouts, so it is not bumped along with home-manager. home.username and
  # home.homeDirectory come from users.users (hosts/common/home-manager.nix).
  home.stateVersion = "25.05";
}
