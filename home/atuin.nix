# Shell history in atuin: fuzzy search across every directory, in a compact
# 20-line view with a preview.
{
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      search_mode = "fuzzy";
      filter_mode = "global";
      show_preview = true;
      inline_height = 20;
      style = "compact";
    };
  };
}
