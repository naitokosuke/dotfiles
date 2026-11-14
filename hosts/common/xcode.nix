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
  xcodebuild = "${developerDir}/usr/bin/xcodebuild";
in
{
  homebrew.masApps.Xcode = 497799835;

  # Runs after the homebrew activation step, so Xcode is already installed on
  # a fresh machine. Each step only runs when Xcode reports it is still
  # needed, and a failing step warns instead of aborting the rest of the
  # activation (#549).
  #
  # Xcode is selected with `xcode-select` rather than DEVELOPER_DIR: the
  # /usr/bin shims and GUI apps read the selected directory, not the
  # environment. The license is accepted automatically, also when an Xcode
  # update brings a new one: the App Store updates Xcode unattended, and an
  # unaccepted license would break every build until someone noticed.
  system.activationScripts.postActivation.text = ''
    if [ -d ${developerDir} ]; then
      if [ "$(/usr/bin/xcode-select --print-path)" != ${developerDir} ]; then
        echo "selecting Xcode as the active developer directory..." >&2
        /usr/bin/xcode-select --switch ${developerDir} ||
          echo "warning: could not select Xcode" >&2
      fi
      if ! ${xcodebuild} -license check >/dev/null 2>&1; then
        echo "accepting the Xcode license..." >&2
        ${xcodebuild} -license accept ||
          echo "warning: could not accept the Xcode license" >&2
      fi
      if ! ${xcodebuild} -checkFirstLaunchStatus >/dev/null 2>&1; then
        echo "installing the system packages Xcode asks for on first launch..." >&2
        ${xcodebuild} -runFirstLaunch ||
          echo "warning: Xcode first-launch setup failed" >&2
      fi
    fi
  '';
}
