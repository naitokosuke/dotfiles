# gwq is to worktrees what ghq is to clones. The TOML config is generated from
# Nix: `worktree.basedir` is the shared source root, and the naming template
# appends `---<branch>` to the repository path, so each worktree sits beside
# the clone it came from (home/claude-sandbox.nix relies on that layout).
{
  config,
  pkgs,
  ...
}:

let
  tomlFormat = pkgs.formats.toml { };
in
{
  xdg.configFile."gwq/config.toml".source = tomlFormat.generate "gwq-config.toml" {
    worktree.basedir = config.naitokosuke.srcDirectory;
    naming.template = "{{.Host}}/{{.Owner}}/{{.Repository}}---{{.Branch}}";
  };
}
