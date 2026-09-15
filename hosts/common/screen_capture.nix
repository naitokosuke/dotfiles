{
  config,
  ...
}:

{
  system.defaults.screencapture = {
    location = "${config.naitokosuke.homeDirectory}/Pictures/screenshots/";
  };
}
