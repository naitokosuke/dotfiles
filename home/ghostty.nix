# Ghostty is the terminal: Catppuccin Mocha, ligatures off, and no `command`,
# so it starts the login shell, which is zsh.
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
      # Ghostty implements fixterms, so Shift+Enter sends an escape sequence
      # that breaks multi-line input in Claude Code, which expects a newline.
      # The keybind sends a literal newline instead, matching iTerm2
      # (ghostty-org/ghostty#7780).
      keybind = "shift+enter=text:\\n";
    };
  };
}
