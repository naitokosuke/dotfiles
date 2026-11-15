# A Dock that stays out of the way and keeps a predictable width.
{
  system.defaults.dock = {
    ## Auto-hide and suppress recents
    # Hidden until the cursor reaches the edge, and without recent apps, so it
    # does not grow as projects change.
    autohide = true;
    show-recents = false;

    ## Sizing and animation
    # Small tiles that magnify on hover, the sharper scale effect, and no
    # bouncing icons on launch.
    tilesize = 50;
    magnification = true;
    largesize = 64;
    orientation = "bottom";
    mineffect = "scale";
    launchanim = false;
  };
}
