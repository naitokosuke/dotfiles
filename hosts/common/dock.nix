# The Dock auto-hides and keeps recent apps off, so its width stays
# predictable, with a small tile that magnifies on hover.
{
  system.defaults.dock = {
    autohide = true;
    show-recents = false;
    ## Sizing and animation
    # Tiles render at 50px and magnify to 64px on hover. `scale` is sharper
    # than the genie effect, and `launchanim = false` drops the bouncing icon
    # during app launch.
    tilesize = 50;
    magnification = true;
    largesize = 64;
    orientation = "bottom";
    mineffect = "scale";
    launchanim = false;
  };
}
