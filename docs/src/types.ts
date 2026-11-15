export type Lang = "nix" | "md" | "ts" | "json" | "lock" | "yaml" | "toml" | "text";

export interface WalkthroughSection {
  readonly title: string;
  readonly prose: string;
  readonly lines?: readonly [number, number];
}

export interface Walkthrough {
  readonly intro?: string;
  readonly sections: readonly WalkthroughSection[];
}

/** `nix eval --json .#docsData`, as written by docs/facts.nix. */
export interface Facts {
  readonly hosts: Readonly<Record<string, HostFacts>>;
  readonly inputs: readonly {
    readonly name: string;
    readonly source: string;
    readonly rev: string | null;
    readonly lastModified: number | null;
  }[];
  readonly packages: readonly {
    readonly name: string;
    readonly version: string;
    readonly description: string | null;
    readonly homepage: string | null;
  }[];
  readonly options: readonly {
    readonly name: string;
    readonly type: string | null;
    readonly default: string | null;
    readonly description: string;
  }[];
}

export interface PackageFact {
  readonly name: string;
  readonly version: string;
}

export interface HostFacts {
  readonly casks: readonly string[];
  readonly masApps: Readonly<Record<string, number>>;
  readonly requiredCasks: Readonly<Record<string, string>>;
  readonly systemPackages: readonly PackageFact[];
  readonly homePackages: readonly PackageFact[];
  readonly programs: { readonly darwin: readonly string[]; readonly home: readonly string[] };
  readonly launchd: { readonly daemons: readonly string[]; readonly agents: readonly string[] };
}

export interface FactTable {
  readonly title: string;
  readonly caption: string;
  readonly columns: readonly string[];
  readonly rows: readonly (readonly string[])[];
}

export interface FileEntry {
  readonly path: string;
  readonly name: string;
  readonly ext: string;
  readonly lang: Lang;
  readonly content: string;
  readonly walkthrough?: Walkthrough;
}

export interface DirNode {
  readonly type: "dir";
  readonly name: string;
  readonly path: string;
  readonly children: TreeNode[];
}

export interface FileNode {
  readonly type: "file";
  readonly name: string;
  readonly path: string;
  readonly file: FileEntry;
}

export type TreeNode = DirNode | FileNode;

export type Route = { kind: "home" } | { kind: "file"; path: string };
