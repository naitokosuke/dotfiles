# gwq does for worktrees what ghq does for clones, with its TOML config
# generated here.
{
  config,
  pkgs,
  ...
}:

let
  tomlFormat = pkgs.formats.toml { };
in
{
  ## Where worktrees land
  # Under the same root as ghq, as `<repository>---<branch>`, so each worktree
  # sits beside the clone it came from.
  xdg.configFile."gwq/config.toml".source = tomlFormat.generate "gwq-config.toml" {
    worktree.basedir = config.naitokosuke.srcDirectory;
    naming.template = "{{.Host}}/{{.Owner}}/{{.Repository}}---{{.Branch}}";
  };
}
