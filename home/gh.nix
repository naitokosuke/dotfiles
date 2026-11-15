# The GitHub CLI over SSH, with vim as its editor and `gh co` for checking out
# pull requests. gh-sub-issue is not in nixpkgs, so it comes from ../pkgs.
{
  pkgs,
  ...
}:

{
  programs.gh = {
    enable = true;
    extensions = [
      pkgs.gh-actions-lock
      pkgs.naitokosuke.gh-sub-issue
    ];
    settings = {
      version = 1;
      git_protocol = "ssh";
      editor = "vim";
      prompt = "enabled";
      prefer_editor_prompt = "disabled";
      aliases = {
        co = "pr checkout";
      };
    };
  };
}
