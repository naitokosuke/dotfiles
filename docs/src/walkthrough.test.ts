/**
 * The walkthrough parser decides what the site shows for every file, so the
 * conventions it reads are pinned here.
 *
 * @module-tag walkthrough
 */
import { expect, test } from "vite-plus/test";
import { parseWalkthrough } from "./walkthrough.ts";

const nix = `# The intro, first paragraph.
#
# Second paragraph.
{ pkgs, ... }:

{
  ## Enable
  # Why it is enabled.
  programs.foo = {
    enable = true;

    settings = {
      a = 1;
    };
  };
  programs.bar.enable = true;

  ## Trailing
  # Code with nothing after it.
  home.stateVersion = "25.05";
}
`;

test("the leading comment block is the intro", () => {
  const walkthrough = parseWalkthrough(nix, "nix");
  expect(walkthrough?.intro).toBe("The intro, first paragraph.\n\nSecond paragraph.");
});

test("a ## comment opens a section whose excerpt spans the block and its siblings", () => {
  const sections = parseWalkthrough(nix, "nix")?.sections ?? [];
  expect(sections.map((s) => s.title)).toEqual(["Enable", "Trailing"]);
  expect(sections[0]?.prose).toBe("Why it is enabled.");
  // `programs.foo = {` through `programs.bar.enable = true;`, including the
  // blank line inside the block but not the one after the siblings.
  expect(sections[0]?.lines).toEqual([9, 16]);
  // The closing `}` of the enclosing attrset is not part of the excerpt.
  expect(sections[1]?.lines).toEqual([20, 20]);
});

test("a file without comments has no walkthrough", () => {
  expect(parseWalkthrough("{\n  a = 1;\n}\n", "nix")).toBeUndefined();
});

test("a section has no excerpt unless code follows its comment directly", () => {
  const walkthrough = parseWalkthrough(
    "## Absent on purpose\n# Nothing is declared here.\n\n  a = 1;\n## At the end\n# Nothing follows.\n",
    "nix",
  );
  expect(walkthrough?.intro).toBeUndefined();
  expect(walkthrough?.sections).toEqual([
    { title: "Absent on purpose", prose: "Nothing is declared here." },
    { title: "At the end", prose: "Nothing follows." },
  ]);
});

test("yaml steps end at the next blank line", () => {
  const yaml = `# Workflow intro.
name: check

jobs:
  check:
    steps:
      - uses: actions/checkout@v7

      ## Check
      # Builds everything.
      - run: nix flake check
        env:
          A: b

      - run: echo done
`;
  const walkthrough = parseWalkthrough(yaml, "yaml");
  expect(walkthrough?.intro).toBe("Workflow intro.");
  expect(walkthrough?.sections).toEqual([
    { title: "Check", prose: "Builds everything.", lines: [11, 13] },
  ]);
});

test("markdown is its own prose and gets no walkthrough", () => {
  expect(parseWalkthrough("# Heading\n\n## Section\n", "md")).toBeUndefined();
});
