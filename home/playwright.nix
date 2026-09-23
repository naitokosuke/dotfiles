# Playwright downloads its browser builds (Chromium, its headless shell,
# ffmpeg — around 550 MB) into a machine-wide cache it manages itself. They are
# not npm packages, so no lockfile describes them and no install step notices
# when they disappear; the first symptom is a browser test failing with
# "Executable doesn't exist at ..." in a project nothing has changed in.
#
# On macOS that cache defaults to ~/Library/Caches/ms-playwright, which the OS
# counts as purgeable space and reclaims silently under disk pressure — so the
# browsers do disappear, and recovery is a ~280 MB `playwright install`
# (issue #476). PLAYWRIGHT_BROWSERS_PATH moves the registry to a directory
# macOS treats as ordinary data. Everything else is unchanged: browsers stay
# runtime-managed by Playwright, the same decision recorded in
# pkgs/playwright-cli.nix, and the cache stays shared across projects.
#
# ~/.cache/ms-playwright is Playwright's own default on Linux, so the path
# matches upstream docs and the cache keys every CI recipe already uses.
{ config, ... }:

let
  browsersPath = "${config.xdg.cacheHome}/ms-playwright";
in
{
  home.sessionVariables.PLAYWRIGHT_BROWSERS_PATH = browsersPath;

  # home.sessionVariables only reaches zsh; Nushell needs it set explicitly.
  programs.nushell.environmentVariables.PLAYWRIGHT_BROWSERS_PATH = browsersPath;
}
