# zoxide learns which directories are visited and jumps to the best match with
# `z`.
{
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
}
