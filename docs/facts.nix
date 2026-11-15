# What the walkthrough site shows as facts (installed casks, package versions,
# enabled programs, …), evaluated from the configuration instead of restated
# in prose (#612). The flake exposes it as `docsData`, and
# `nix eval --json .#docsData` turns it into docs/src/facts.generated.json.
# Only evaluated, never built, so a Linux runner can produce it for the
# darwin hosts.
{
  lib,
  self,
  darwinConfigurations,
  packages,
}:

let
  lock = lib.importJSON (self + "/flake.lock");

  byName = lib.sort (a: b: a.name < b.name);

  packageList =
    ps:
    byName (
      lib.unique (
        map (p: {
          name = lib.getName p;
          version = lib.getVersion p;
        }) ps
      )
    );

  # `programs.<name>.enable`, for the modules that have one. Renamed options
  # are invisible and print a deprecation warning when read, so they are
  # skipped by their option rather than read.
  enabledPrograms =
    { options, config }:
    lib.sort lib.lessThan (
      lib.attrNames (
        lib.filterAttrs (
          name: option:
          let
            enabled = builtins.tryEval (config.programs.${name}.enable == true);
          in
          (option.enable.visible or true) != false && enabled.success && enabled.value
        ) (lib.filterAttrs (_: option: option ? enable) options.programs)
      )
    );

  host =
    system:
    let
      inherit (system) config options;
      inherit (config.naitokosuke) username;
      home = config.home-manager.users.${username};
      homeOptions = options.home-manager.users.valueMeta.attrs.${username}.configuration.options;
    in
    {
      casks = map (cask: cask.name) config.homebrew.casks;
      masApps = config.homebrew.masApps;
      requiredCasks = home.naitokosuke.requiredCasks;
      systemPackages = packageList config.environment.systemPackages;
      homePackages = packageList home.home.packages;
      programs = {
        darwin = enabledPrograms { inherit options config; };
        home = enabledPrograms {
          options = homeOptions;
          config = home;
        };
      };
      launchd = {
        daemons = lib.attrNames config.launchd.daemons;
        agents = lib.attrNames (lib.filterAttrs (_: agent: agent.enable) home.launchd.agents);
      };
    };

  # Root inputs only; the rest are their transitive dependencies.
  input =
    name: nodeName:
    let
      node = lock.nodes.${nodeName};
      inherit (node) original;
      source =
        if original.type == "github" then
          "github:${original.owner}/${original.repo}${lib.optionalString (original ? ref) "/${original.ref}"}"
        else
          original.url or original.type;
    in
    {
      inherit name source;
      rev = node.locked.rev or null;
      lastModified = node.locked.lastModified or null;
    };

  option = o: {
    inherit (o) name description;
    type = o.type or null;
    default = o.default.text or null;
  };
in
{
  hosts = lib.mapAttrs (_: host) darwinConfigurations;

  inputs = byName (lib.mapAttrsToList input lock.nodes.root.inputs);

  packages = byName (
    lib.mapAttrsToList (name: p: {
      inherit name;
      inherit (p) version;
      description = p.meta.description or null;
      homepage = p.meta.homepage or null;
    }) packages
  );

  # The options are the same in every host, so the first one is read.
  options = map option (
    lib.optionAttrSetToDocList (lib.head (lib.attrValues darwinConfigurations)).options.naitokosuke
  );
}
