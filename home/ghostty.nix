# Ghostty, the terminal: Catppuccin Mocha with ligatures off. With no
# `command` set it starts the login shell, Zsh.
{
  programs.ghostty = {
    enable = true;
    # The app is a cask (hosts/common/homebrew.nix); only its config is
    # managed here.
    package = null;
    settings = {
      theme = "Catppuccin Mocha";
      font-feature = [
        "-calt"
        "-dlig"
      ];

      ## Shift+Enter
      # Ghostty implements fixterms, which sends escape sequence [27;2;13~ for Shift+Enter.
      # This breaks multi-line input in Claude Code CLI (which expects a newline character).
      # Rebind Shift+Enter to send \n directly, matching iTerm2's behavior.
      # See: https://github.com/ghostty-org/ghostty/discussions/7780
      keybind = "shift+enter=text:\\n";
    };
  };
}
