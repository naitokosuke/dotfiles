/**
 * The fact tables are built from `nix eval --json .#docsData`; this pins how
 * that JSON maps onto the pages, using a small fixture instead of Nix.
 *
 * @module-tag facts
 */
import { expect, test } from "vite-plus/test";
import { factsFor } from "./facts.ts";
import type { Facts } from "./types.ts";

const fixture: Facts = {
  hosts: {
    "Mac-big": {
      casks: ["adrafinil", "raycast"],
      masApps: { Xcode: 497799835 },
      requiredCasks: { adrafinil: "home/adrafinil.nix runs the Adrafinil CLI" },
      systemPackages: [
        { name: "fd", version: "10.5.2" },
        { name: "darwin-rebuild", version: "" },
      ],
      homePackages: [{ name: "git", version: "2.56.0" }],
      programs: { darwin: ["zsh"], home: ["git", "zsh"] },
      launchd: { daemons: ["nh-clean"], agents: ["gomi-prune"] },
    },
  },
  inputs: [
    {
      name: "nixpkgs",
      source: "github:NixOS/nixpkgs/nixpkgs-unstable",
      rev: "9397dcb09c9598a33509fbc0cce699bd4e6c84d5",
      lastModified: 1794408178,
    },
  ],
  packages: [{ name: "frog", version: "1.1.0", description: "Friction logging", homepage: null }],
  options: [
    {
      name: "naitokosuke.username",
      type: "string",
      default: '"naitokosuke"',
      description: "Primary user account name.",
    },
  ],
};

test("flake.nix lists the locked inputs with a short revision and the date", () => {
  expect(factsFor("flake.nix", fixture)[0]?.rows).toEqual([
    ["nixpkgs", "github:NixOS/nixpkgs/nixpkgs-unstable", "9397dcb", "2026-11-11"],
  ]);
});

test("casks show the module that requires them", () => {
  expect(factsFor("hosts/common/homebrew.nix", fixture)[0]?.rows).toEqual([
    ["adrafinil", "home/adrafinil.nix runs the Adrafinil CLI"],
    ["raycast", ""],
  ]);
});

test("a package without a version shows a dash", () => {
  expect(factsFor("hosts/common/packages.nix", fixture)[0]?.rows).toEqual([
    ["fd", "10.5.2"],
    ["darwin-rebuild", "—"],
  ]);
});

test("home/default.nix gets programs, packages and agents", () => {
  expect(factsFor("home/default.nix", fixture).map((t) => t.title)).toEqual([
    "Enabled programs",
    "Home packages",
    "launchd agents",
  ]);
});

test("files without facts, or a missing JSON file, give no tables", () => {
  expect(factsFor("home/zoxide.nix", fixture)).toEqual([]);
  expect(factsFor("flake.nix", undefined)).toEqual([]);
});
