# atuin replaces the shell history with a synced, fuzzy-searchable store. The
# search is global, so the same history surfaces from any directory, in a
# compact 20-line UI with a preview of the selected command.
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
