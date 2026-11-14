# macOS counts Playwright's default browser cache
# (~/Library/Caches/ms-playwright) as purgeable and reclaims it silently under
# disk pressure, after which browser tests fail with "Executable doesn't
# exist" (#476). PLAYWRIGHT_BROWSERS_PATH moves the cache to a directory macOS
# treats as ordinary data: ~/.cache/ms-playwright, Playwright's own default on
# Linux. The browsers stay runtime-managed (see pkgs/playwright-cli.nix).
{ config, ... }:

let
  browsersPath = "${config.xdg.cacheHome}/ms-playwright";
in
{
  home.sessionVariables.PLAYWRIGHT_BROWSERS_PATH = browsersPath;
}
