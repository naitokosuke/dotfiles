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
