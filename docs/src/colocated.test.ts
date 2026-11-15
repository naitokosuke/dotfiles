import { describe, expect, test } from "vite-plus/test";
import { readWalkthrough } from "./colocated.ts";

const nix = `# What this module is for.
#
# A second paragraph.
{ pkgs, ... }:

{
  # A plain comment, not a section.
  home.packages = [ pkgs.hello ];

  ## Shift+Enter
  # Sends a newline instead of submitting.
  programs.foo = {
    enable = true;
    settings = {
      a = 1;
    };
  };
  programs.bar.enable = true;

  ## Prose only
  # Nothing follows this one.

  ## Script
  # An indented string.
  script = ''
    echo hi

    echo there
  '';
}`;

describe("readWalkthrough", () => {
  const walkthrough = readWalkthrough(nix, "nix");

  test("the leading comment block is the intro", () => {
    expect(walkthrough?.intro).toBe("What this module is for.\n\nA second paragraph.");
  });

  test("a section runs over its block and the sibling lines after it", () => {
    expect(walkthrough?.sections?.[0]).toEqual({
      title: "Shift+Enter",
      prose: "Sends a newline instead of submitting.",
      lines: [12, 18],
    });
  });

  test("a section with no code after its prose has no lines", () => {
    expect(walkthrough?.sections?.[1]).toEqual({
      title: "Prose only",
      prose: "Nothing follows this one.",
    });
  });

  test("an indented string with blank lines inside", () => {
    expect(walkthrough?.sections?.[2]?.lines).toEqual([25, 29]);
  });

  test("plain comments do not open sections", () => {
    expect(walkthrough?.sections).toHaveLength(3);
  });

  test("a section inside a block cuts the outer excerpt short", () => {
    const nested = `{
  ## Settings
  # The whole set.
  settings = {
    theme = "dark";

    ## Permissions
    # Part of it.
    permissions = {
      deny = [ ];
    };
  };
}`;
    const sections = readWalkthrough(nested, "nix")?.sections;
    expect(sections?.map((s) => s.lines)).toEqual([
      [4, 5],
      [9, 11],
    ]);
  });

  test("YAML keys own their more deeply indented lines", () => {
    const yaml =
      "name: x\n\non:\n  ## Triggers\n  # Pushes to main.\n  push:\n    branches: [main]\n\njobs: {}\n";
    expect(readWalkthrough(yaml, "yaml")?.sections?.[0]?.lines).toEqual([6, 7]);
  });

  test("files without # comments have no walkthrough", () => {
    expect(readWalkthrough("# Title\n", "md")).toBeUndefined();
    expect(readWalkthrough("{ }\n", "nix")).toBeUndefined();
  });
});
