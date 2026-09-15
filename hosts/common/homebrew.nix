{
  config,
  inputs,
  pkgs,
  ...
}:

let
  # Homebrew calls `sudo --reset-timestamp` on every invocation
  # (`Library/Homebrew/brew.sh`), and cask uninstall directives such as
  # `launchctl:` shell out to sudo once per launchd domain, so a cask upgrade
  # during activation asks for a password repeatedly on the very terminal that
  # `darwin-rebuild-nom` has `nom` repainting. Homebrew's `sudo_prefix` adds
  # `-A` when SUDO_ASKPASS is set, and `bin/brew` allowlists that variable
  # through its environment filter, so the prompt moves to a GUI dialog that
  # says what it is asking for. See issue #416.
  sudoAskpass = pkgs.writeShellScript "homebrew-sudo-askpass" ''
    exec /usr/bin/osascript \
      -e 'set reply to display dialog "Homebrew needs administrator rights to update casks during nix-darwin activation." with title "darwin-rebuild" default answer "" with icon caution with hidden answer' \
      -e 'text returned of reply'
  '';
in

{
  nix-homebrew = {
    enable = true;
    enableRosetta = false;
    user = config.naitokosuke.username;
    autoMigrate = true;
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
      "productdevbook/homebrew-tap" = inputs.homebrew-productdevbook;
      "stablyai/homebrew-orca" = inputs.homebrew-orca;
    };
    # Taps are read-only and pinned by flake.lock; `brew tap` is disabled.
    mutableTaps = false;
  };

  homebrew = {
    enable = true;

    # Mirror the nix-homebrew-pinned taps into the Brewfile so
    # `brew bundle` cleanup does not try to untap them.
    taps = builtins.attrNames config.nix-homebrew.taps;

    # Fully declarative (issue #363): cask definitions come from the
    # flake-pinned taps (HOMEBREW_NO_INSTALL_FROM_API), so activation
    # converges installed apps to what flake.lock pins — new versions arrive
    # via `nix flake update` + rebuild, and casks removed from the list below
    # are uninstalled. Most of these apps still self-update independently.
    onActivation = {
      autoUpdate = false;
      upgrade = true;
      cleanup = "uninstall";
      extraEnv = {
        HOMEBREW_NO_INSTALL_FROM_API = "1";
        SUDO_ASKPASS = "${sudoAskpass}";
      };
    };

    casks = [
      # Keeps the Mac awake only while an AI agent is working; the Claude Code
      # hooks that drive it live in home/claude.nix. The cask requires macOS 26
      # (`depends_on macos: :tahoe`) and is `auto_updates true` — Adrafinil
      # swaps itself in place, so the flake.lock pin is only the floor version.
      "adrafinil"
      "alt-tab"
      "arc"
      "blender"
      "discord"
      "ghostty"
      "google-chrome"
      "monitorcontrol"
      "obs"
      "obsidian"
      "productdevbook/tap/portkiller"
      "raycast"
      "scroll-reverser"
      # Ships the `orca` CLI as a `binary` stanza, so the cask covers both the
      # app and the shell entrypoint. The cask is `auto_updates true`; Orca
      # swaps itself in place via electron-updater, so the flake.lock pin is
      # only the floor version installed on a fresh machine.
      "stablyai/orca/orca"
      "visual-studio-code"
    ];
  };
}
