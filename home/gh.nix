# The GitHub CLI: SSH as the git protocol, vim as the editor, `co` for
# `pr checkout`. gh-sub-issue is not in nixpkgs, so it comes from ../pkgs as
# the official prebuilt binary, version-tracked by nvfetcher.
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
