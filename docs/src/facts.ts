/**
 * Facts evaluated from the configuration (#612), shown on the page of the
 * file that declares them, so the prose never has to restate what is
 * installed or which version is locked.
 *
 * `vp run facts` writes facts.generated.json with `nix eval`; the build and
 * deploy scripts run it first. Without the file the pages simply have no fact
 * tables, so `vp check` and `vp test` work without Nix.
 */
import type { FactTable, Facts, PackageFact } from "./types.ts";

const generated = import.meta.glob<Facts>("./facts.generated.json", {
  eager: true,
  import: "default",
});

export const facts: Facts | undefined = Object.values(generated)[0];

const packageRows = (packages: readonly PackageFact[]): string[][] =>
  packages.map((p) => [p.name, p.version || "—"]);

const nameRows = (names: readonly string[]): string[][] => names.map((name) => [name]);

const day = (seconds: number | null): string =>
  seconds === null ? "—" : new Date(seconds * 1000).toISOString().slice(0, 10);

export function factsFor(path: string, data: Facts | undefined): FactTable[] {
  if (!data) return [];
  const hostName = Object.keys(data.hosts)[0];
  const host = hostName === undefined ? undefined : data.hosts[hostName];
  const evaluated = `Evaluated from darwinConfigurations.${hostName ?? "?"}.`;
  const locked = "Read from flake.lock.";

  const customPackages: FactTable = {
    title: "Packaged here",
    caption: "Evaluated from the flake's packages output.",
    columns: ["Package", "Version", "Description"],
    rows: data.packages.map((p) => [p.name, p.version, p.description ?? ""]),
  };

  switch (path) {
    case "flake.nix":
      return [
        {
          title: "Locked inputs",
          caption: locked,
          columns: ["Input", "Source", "Revision", "Date"],
          rows: data.inputs.map((i) => [
            i.name,
            i.source,
            i.rev?.slice(0, 7) ?? "—",
            day(i.lastModified),
          ]),
        },
      ];
    case "nvfetcher.toml":
    case "pkgs/default.nix":
      return [customPackages];
    case "modules/naitokosuke/default.nix":
      return [
        {
          title: "Options",
          caption: "Listed with lib.optionAttrSetToDocList.",
          columns: ["Option", "Type", "Default", "Description"],
          rows: data.options.map((o) => [o.name, o.type ?? "", o.default ?? "", o.description]),
        },
      ];
  }

  if (!host) return [];
  switch (path) {
    case "hosts/common/default.nix":
      return [
        {
          title: "Enabled programs",
          caption: evaluated,
          columns: ["programs.*"],
          rows: nameRows(host.programs.darwin),
        },
        {
          title: "launchd daemons",
          caption: evaluated,
          columns: ["Daemon"],
          rows: nameRows(host.launchd.daemons),
        },
      ];
    case "hosts/common/packages.nix":
      return [
        {
          title: "System packages",
          caption: `${evaluated} Includes what nix-darwin adds on its own.`,
          columns: ["Package", "Version"],
          rows: packageRows(host.systemPackages),
        },
      ];
    case "hosts/common/homebrew.nix":
    case "home/required-casks.nix":
      return [
        {
          title: "Casks",
          caption: evaluated,
          columns: ["Cask", "Required by"],
          rows: host.casks.map((cask) => [cask, host.requiredCasks[cask] ?? ""]),
        },
      ];
    case "hosts/common/xcode.nix":
      return [
        {
          title: "Mac App Store apps",
          caption: evaluated,
          columns: ["App", "App Store ID"],
          rows: Object.entries(host.masApps).map(([name, id]) => [name, String(id)]),
        },
      ];
    case "home/default.nix":
      return [
        {
          title: "Enabled programs",
          caption: evaluated,
          columns: ["programs.*"],
          rows: nameRows(host.programs.home),
        },
        {
          title: "Home packages",
          caption: `${evaluated} Includes what the enabled programs install.`,
          columns: ["Package", "Version"],
          rows: packageRows(host.homePackages),
        },
        {
          title: "launchd agents",
          caption: evaluated,
          columns: ["Agent"],
          rows: nameRows(host.launchd.agents),
        },
      ];
  }
  return [];
}
