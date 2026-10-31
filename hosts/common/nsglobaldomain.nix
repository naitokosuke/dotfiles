# Global macOS preferences that have no app of their own.
{ ... }:

{
  system.defaults.NSGlobalDomain = {
    # The fastest key repeat the OS exposes, with the delay before it kicks
    # in cut to about 200 ms.
    KeyRepeat = 1;
    InitialKeyRepeat = 20;

    # The menu bar slides in only when the cursor hits the top edge.
    _HIHideMenuBar = true;

    # Natural scroll direction, and scrollbars only while scrolling.
    "com.apple.swipescrolldirection" = true;
    AppleShowScrollBars = "WhenScrolling";
  };
}
