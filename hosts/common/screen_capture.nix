# Screenshots go to ~/Pictures/screenshots instead of the Desktop, where they
# would mix with everything else.
{
  config,
  ...
}:

{
  system.defaults.screencapture = {
    location = "${config.naitokosuke.homeDirectory}/Pictures/screenshots/";
  };
}
