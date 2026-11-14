# Custom packages for tools not available in nixpkgs (issue #342).
#
# Most of these install the upstream release binary instead of building from
# source, which is the opposite of what nixpkgs does. The choice is made per
# package (#551):
#
# * cclens: upstream writes the version into Cargo.toml only while releasing,
#   so a source build would have to repeat that release step.
# * frog: a TypeScript project compiled into a single binary by its own
#   release pipeline.
# * gh-sub-issue: buildGoModule needs a vendorHash, which nvfetcher cannot keep
#   in step with version bumps.
# * vite-plus: the launcher is one crate of a large Rust workspace, and the
#   toolchain it runs is prebuilt on npm either way.
# * playwright-cli: built from source, because it is only published on npm.
{ pkgs }:
let
  sources = pkgs.callPackage ./_sources/generated.nix { };
in
{
  cclens = pkgs.callPackage ./cclens.nix { inherit sources; };
  frog = pkgs.callPackage ./frog.nix { inherit sources; };
  gh-sub-issue = pkgs.callPackage ./gh-sub-issue.nix { inherit sources; };
  playwright-cli = pkgs.callPackage ./playwright-cli.nix { inherit sources; };
  vite-plus = pkgs.callPackage ./vite-plus.nix { inherit sources; };
}
