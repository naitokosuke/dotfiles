# Holds back releases younger than the cooldown in the nvfetcher workflow
# (#584). nvfetcher has no such option, so each `src.github` in nvfetcher.toml
# is replaced with a fixed `src.manual` version.
#
# `releases` is a directory with one `<name>.json` per source, holding the
# output of `gh api repos/<owner>/<repo>/releases`.
{
  cutoff ? null,
  releases ? null,
}:
let
  sources = builtins.fromTOML (builtins.readFile ../nvfetcher.toml);
  pinned = builtins.fromJSON (builtins.readFile ../pkgs/_sources/generated.json);

  lines = f: builtins.concatStringsSep "" (builtins.attrValues (builtins.mapAttrs f sources));

  # The newest release that is old enough. A pin that is already newer than
  # that is kept, so nothing is downgraded. GitHub lists releases newest
  # first, and ISO 8601 timestamps compare as strings.
  select =
    name: source:
    let
      prefix = source.src.prefix or "";
      current = prefix + pinned.${name}.version;
      candidates = builtins.filter (
        release:
        !release.draft
        && !release.prerelease
        && builtins.substring 0 (builtins.stringLength prefix) release.tag_name == prefix
        && (release.tag_name == current || release.published_at <= cutoff)
      ) (builtins.fromJSON (builtins.readFile "${releases}/${name}.json"));
    in
    if candidates == [ ] then current else (builtins.head candidates).tag_name;
in
{
  # `<name> <owner>/<repo>` per source.
  repos = lines (name: source: "${name} ${source.src.github}\n");

  # A sed script that pins every source.
  sed = lines (
    name: source: ''s|src.github = "${source.src.github}"|src.manual = "${select name source}"|'' + "\n"
  );
}
