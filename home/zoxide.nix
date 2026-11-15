# zoxide learns which directories are used, by frequency and recency, so
# `z <fragment>` jumps to the best match.
{
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
}
