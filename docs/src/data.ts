import type { DirNode, FileEntry, Lang, TreeNode } from "./types.ts";
import { explanations } from "./explanations.ts";

const rawModules: Record<string, string> = {
  ...import.meta.glob("../../README.md", {
    eager: true,
    query: "?raw",
    import: "default",
  }),
  ...import.meta.glob("../../flake.nix", {
    eager: true,
    query: "?raw",
    import: "default",
  }),
  ...import.meta.glob("../../nvfetcher.toml", {
    eager: true,
    query: "?raw",
    import: "default",
  }),
  ...import.meta.glob("../../pkgs/**/*.nix", {
    eager: true,
    query: "?raw",
    import: "default",
  }),
  ...import.meta.glob("../../.github/workflows/*.yml", {
    eager: true,
    query: "?raw",
    import: "default",
  }),
  ...import.meta.glob("../../.github/dependabot.yml", {
    eager: true,
    query: "?raw",
    import: "default",
  }),
  ...import.meta.glob("../../hosts/**/*.nix", {
    eager: true,
    query: "?raw",
    import: "default",
  }),
  ...import.meta.glob("../../modules/**/*.nix", {
    eager: true,
    query: "?raw",
    import: "default",
  }),
  ...import.meta.glob("../../home/**/*.nix", {
    eager: true,
    query: "?raw",
    import: "default",
  }),
  ...import.meta.glob("../AGENTS.md", {
    eager: true,
    query: "?raw",
    import: "default",
  }),
} as Record<string, string>;

const langByExt: Readonly<Record<string, Lang>> = {
  ".nix": "nix",
  ".md": "md",
  ".ts": "ts",
  ".tsx": "ts",
  ".json": "json",
  ".lock": "lock",
  ".yaml": "yaml",
  ".yml": "yaml",
  ".toml": "toml",
};

function langFromName(name: string): Lang {
  const dot = name.lastIndexOf(".");
  if (dot === -1) return "text";
  return langByExt[name.slice(dot).toLowerCase()] ?? "text";
}

function toRepoPath(viteKey: string): string {
  if (viteKey.startsWith("../../")) return viteKey.slice("../../".length);
  if (viteKey.startsWith("../")) return `docs/${viteKey.slice("../".length)}`;
  return viteKey;
}

function makeEntry(repoPath: string, content: string): FileEntry {
  const name = repoPath.split("/").pop() ?? repoPath;
  const dot = name.lastIndexOf(".");
  const ext = dot === -1 ? "" : name.slice(dot);
  const meta = explanations[repoPath];
  return {
    path: repoPath,
    name,
    ext,
    lang: langFromName(name),
    content,
    about: meta?.about,
    tags: meta?.tags,
    walkthrough: meta?.walkthrough,
  };
}

export const files: readonly FileEntry[] = Object.entries(rawModules)
  .map(([key, content]) => makeEntry(toRepoPath(key), content))
  .sort((a, b) => a.path.localeCompare(b.path));

export const filesByPath: ReadonlyMap<string, FileEntry> = new Map(
  files.map((entry) => [entry.path, entry] as const),
);

function ensureDir(parent: DirNode, name: string, path: string): DirNode {
  for (const child of parent.children) {
    if (child.type === "dir" && child.name === name) return child;
  }
  const dir: DirNode = { type: "dir", name, path, children: [] };
  parent.children.push(dir);
  return dir;
}

function sortTree(node: DirNode): void {
  node.children.sort((a, b) => {
    if (a.type !== b.type) return a.type === "dir" ? -1 : 1;
    return a.name.localeCompare(b.name, undefined, { sensitivity: "base" });
  });
  for (const child of node.children) {
    if (child.type === "dir") sortTree(child);
  }
}

export const tree: DirNode = (() => {
  const root: DirNode = { type: "dir", name: "dotfiles", path: "", children: [] };
  for (const file of files) {
    const parts = file.path.split("/");
    let current = root;
    for (let i = 0; i < parts.length - 1; i++) {
      const segment = parts[i];
      if (segment === undefined) continue;
      const accPath = parts.slice(0, i + 1).join("/");
      current = ensureDir(current, segment, accPath);
    }
    const last = parts.at(-1);
    if (last === undefined) continue;
    current.children.push({ type: "file", name: last, path: file.path, file });
  }
  sortTree(root);
  return root;
})();

export function ancestorsOf(filePath: string): readonly string[] {
  const parts = filePath.split("/").slice(0, -1);
  const acc: string[] = [];
  let trail = "";
  for (const part of parts) {
    trail = trail ? `${trail}/${part}` : part;
    acc.push(trail);
  }
  return acc;
}

export function flattenFiles(node: TreeNode): FileEntry[] {
  if (node.type === "file") return [node.file];
  return node.children.flatMap(flattenFiles);
}

export function totalLines(): number {
  return files.reduce((sum, file) => sum + file.content.split("\n").length, 0);
}
