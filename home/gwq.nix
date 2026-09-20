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
