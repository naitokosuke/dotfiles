# Ctrl+Space and Ctrl+Option+Space switch the input source by default and
# collide with editor and shell keybinds, so both hotkeys are disabled.
{
  system.defaults.CustomUserPreferences = {
    "com.apple.symbolichotkeys" = {
      AppleSymbolicHotKeys = {
        # "Select the previous input source" (Ctrl+Space)
        "60" = {
          enabled = false;
        };
        # "Select the next source in the Input Menu" (Ctrl+Option+Space)
        "61" = {
          enabled = false;
        };
      };
    };
  };
}
