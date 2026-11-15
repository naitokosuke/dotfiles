# Screenshots go to ~/Pictures/screenshots instead of the Desktop.
{
  config,
  ...
}:

{
  system.defaults.screencapture = {
    location = "${config.naitokosuke.homeDirectory}/Pictures/screenshots/";
  };
}
