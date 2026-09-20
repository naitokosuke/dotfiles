{ ... }:

{
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;

    settings = {
      search_mode = "fuzzy";
      filter_mode = "global";
      show_preview = true;
      inline_height = 20;
      style = "compact";
    };
  };
}
