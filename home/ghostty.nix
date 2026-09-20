{
  pkgs,
  ...
}:

{
  programs.ghostty = {
    enable = true;
    # Ghostty is installed via Homebrew Cask, so don't install via Nix
    package = null;
    settings = {
      command = "${pkgs.nushell}/bin/nu --login";

      theme = "Catppuccin Mocha";
      font-feature = [
        "-calt"
        "-dlig"
      ];

      # Ghostty implements fixterms, which sends escape sequence [27;2;13~ for Shift+Enter.
      # This breaks multi-line input in Claude Code CLI (which expects a newline character).
      # Rebind Shift+Enter to send \n directly, matching iTerm2's behavior.
      # See: https://github.com/ghostty-org/ghostty/discussions/7780
      keybind = "shift+enter=text:\\n";
    };
  };
}
