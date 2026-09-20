# Custom packages for tools not available in nixpkgs (issue #342).
{ pkgs }:
let
  sources = pkgs.callPackage ./_sources/generated.nix { };
in
{
  frog = pkgs.callPackage ./frog.nix { inherit sources; };
  gh-sub-issue = pkgs.callPackage ./gh-sub-issue.nix { inherit sources; };
  gwq = pkgs.callPackage ./gwq.nix { inherit sources; };
  playwright-cli = pkgs.callPackage ./playwright-cli.nix { inherit sources; };
  vite-plus = pkgs.callPackage ./vite-plus.nix { inherit sources; };
}
