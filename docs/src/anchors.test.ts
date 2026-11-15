import { describe, expect, test } from "vite-plus/test";
import { resolveAnchor } from "./anchors.ts";

const nix = `{
  # Comment above the set.
  programs.foo = {
    enable = true;
    settings = {
      a = 1;
    };
  };
  home.stateVersion = "25.05";
  script = ''
    echo hi
  '';
}`;

describe("resolveAnchor", () => {
  test("a set from its comment to its closing line", () => {
    expect(resolveAnchor(nix, "nix", { from: "# Comment above the set." })).toEqual([2, 8]);
  });

  test("a single line that opens nothing", () => {
    expect(resolveAnchor(nix, "nix", { from: "home.stateVersion" })).toEqual([9, 9]);
  });

  test("an indented string", () => {
    expect(resolveAnchor(nix, "nix", { from: "script = ''" })).toEqual([10, 12]);
  });

  test("`to` names the last line by its start", () => {
    expect(resolveAnchor(nix, "nix", { from: "programs.foo", to: "enable" })).toEqual([3, 4]);
  });

  test("`to` on a line that opens a set runs to where it closes", () => {
    expect(resolveAnchor(nix, "nix", { from: "programs.foo", to: "settings = {" })).toEqual([3, 7]);
  });

  test("a Markdown heading runs to the next heading of its level", () => {
    const md = "# Title\n\n## One\n\ntext\n\n```sh\n# not a heading\n```\n\n### Sub\n\n## Two\n";
    expect(resolveAnchor(md, "md", { from: "## One" })).toEqual([3, 11]);
  });

  test("`from` must match exactly one line", () => {
    expect(() => resolveAnchor(nix, "nix", { from: "missing" })).toThrow(/matches 0 lines/);
    expect(() => resolveAnchor(nix, "nix", { from: "};" })).toThrow(/matches 2 lines/);
  });

  test("a missing `to` throws", () => {
    expect(() => resolveAnchor(nix, "nix", { from: "programs.foo", to: "missing" })).toThrow(
      /not found/,
    );
  });
});
