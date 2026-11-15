export type Lang = "nix" | "md" | "ts" | "json" | "lock" | "yaml" | "toml" | "text";

/** Where a walkthrough section points in its file; see `resolveAnchor`. */
export interface CodeAnchor {
  readonly from: string;
  readonly to?: string;
}

/** A walkthrough section as written in `explanations.ts`. */
export interface WalkthroughSectionSource {
  readonly title?: string;
  readonly prose: string;
  readonly code?: CodeAnchor;
}

export interface WalkthroughSource {
  readonly intro: string;
  readonly sections?: readonly WalkthroughSectionSource[];
}

/** A walkthrough section with its anchor resolved against the file. */
export interface WalkthroughSection {
  readonly title?: string;
  readonly prose: string;
  readonly lines?: readonly [number, number];
}

export interface Walkthrough {
  readonly intro: string;
  readonly sections?: readonly WalkthroughSection[];
}

export interface FileEntry {
  readonly path: string;
  readonly name: string;
  readonly ext: string;
  readonly lang: Lang;
  readonly content: string;
  readonly about?: string;
  readonly tags?: readonly string[];
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
