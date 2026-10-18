{ ... }:

# Full Xcode for iOS development (issue #523). The Command Line Tools alone
# cannot build iOS apps or run the Simulator.
#
# Installed from the Mac App Store through `mas`, which nix-darwin's homebrew
# module puts on PATH for `brew bundle`. `mas` can neither sign in nor obtain
# an app the Apple ID has never gotten, and in that case it waits silently
# instead of failing, so on a fresh Apple ID get Xcode once by hand in the
# App Store app before the first rebuild.
# Removing the entry later does not uninstall Xcode (a Homebrew Bundle
# limitation), and the App Store updates it independently of flake.lock.
let
  developerDir = "/Applications/Xcode.app/Contents/Developer";
in
{
  homebrew.masApps.Xcode = 497799835;

  # Runs after the homebrew activation step, so Xcode is already installed on
  # a fresh machine. Guarded so a failed App Store install does not break the
  # rest of the activation.
  system.activationScripts.postActivation.text = ''
    if [ -d ${developerDir} ]; then
      if [ "$(/usr/bin/xcode-select --print-path)" != ${developerDir} ]; then
        echo "selecting Xcode as the active developer directory..." >&2
        /usr/bin/xcode-select --switch ${developerDir}
      fi
      # Accepts the license and installs the system packages Xcode asks for
      # on first launch; both are no-ops once done.
      ${developerDir}/usr/bin/xcodebuild -license accept
      ${developerDir}/usr/bin/xcodebuild -runFirstLaunch
    fi
  '';
}
