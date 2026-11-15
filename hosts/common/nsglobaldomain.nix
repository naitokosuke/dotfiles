# Global macOS preferences that have no app of their own.
{
  system.defaults.NSGlobalDomain = {
    ## Key repeat
    # The fastest key repeat the OS exposes, with the delay before it kicks
    # in cut to about 200 ms.
    KeyRepeat = 1;
    InitialKeyRepeat = 20;

    ## Menu bar
    # Hidden permanently; it slides in only when the cursor hits the top edge.
    # With the auto-hidden Dock, the whole screen goes to the editor or
    # terminal.
    _HIHideMenuBar = true;

    ## Scrolling
    # Natural scroll direction, and scrollbars only while scrolling, so they
    # never pin a column of pixels.
    "com.apple.swipescrolldirection" = true;
    AppleShowScrollBars = "WhenScrolling";
  };
}
