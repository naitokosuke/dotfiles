{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  # A flake input reaches modules as a source tree, without the tag it is
  # pinned to, so the tag is read from the lock.
  brewNode = (lib.importJSON (inputs.self + "/flake.lock")).nodes.brew-src.original;
  brewVersion =
    brewNode.ref or (throw ''
      hosts/common/homebrew.nix expects the brew-src input to be pinned to a tag,
      so the nix-homebrew package can be labelled with that version (#432).
      flake.lock has it as: ${builtins.toJSON brewNode}
    '');

  # Homebrew asks for sudo repeatedly during a cask upgrade, on the terminal
  # `nh` has `nom` repainting. With SUDO_ASKPASS set it runs `sudo -A`, so
  # the prompt becomes a GUI dialog that says what it is for (#416).
  # `sudo -A` never offers Touch ID, so hosts that have it keep the terminal
  # prompt (#504).
  sudoAskpass = pkgs.writeShellScript "homebrew-sudo-askpass" ''
    exec /usr/bin/osascript \
      -e 'set reply to display dialog "Homebrew needs administrator rights to update casks during nix-darwin activation." with title "darwin-rebuild" default answer "" with icon caution with hidden answer' \
      -e 'text returned of reply'
  '';
in

{
  nix-homebrew = {
    enable = true;
    # nix-homebrew labels its package with the brew-src ref from its own
    # flake.lock, so the label is rebuilt from the ref pinned here (#432).
    package = inputs.brew-src // {
      name = "brew-${brewVersion}";
      version = brewVersion;
    };
    enableRosetta = false;
    user = config.naitokosuke.username;
    autoMigrate = true;
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
      "productdevbook/homebrew-tap" = inputs.homebrew-productdevbook;
      "stablyai/homebrew-orca" = inputs.homebrew-orca;
    };
    mutableTaps = false;
    # `brew shellenv` would put Homebrew ahead of the Nix profiles on every
    # interactive zsh start; environment.systemPath below adds the one
    # directory needed, after them.
    enableZshIntegration = false;
  };

  # Cask binaries: `code` for the plan hook in home/claude.nix, and Orca's
  # CLI. Ordered after the Nix profiles and before the system directories.
  environment.systemPath = lib.mkOrder 1100 [ "${config.homebrew.prefix}/bin" ];

  homebrew = {
    enable = true;

    # Mirror the nix-homebrew-pinned taps into the Brewfile so
    # `brew bundle` cleanup does not try to untap them.
    taps = builtins.attrNames config.nix-homebrew.taps;

    # Fully declarative (#363): cask definitions come from the flake-pinned
    # taps, so activation converges the installed apps to flake.lock, and
    # casks removed from the list below are uninstalled. Most of these apps
    # still update themselves independently.
    onActivation = {
      autoUpdate = false;
      upgrade = true;
      cleanup = "uninstall";
      extraEnv = {
        HOMEBREW_NO_INSTALL_FROM_API = "1";
      }
      // lib.optionalAttrs (!config.security.pam.services.sudo_local.touchIdAuth) {
        SUDO_ASKPASS = "${sudoAskpass}";
      };
    };

    # The rule: GUI apps are casks, and CLIs come from Nix (#609). It holds
    # for every app, also the ones nixpkgs could build, so which layer
    # installs an app is never decided per app. Casks keep updating
    # themselves, and their Dock icons and file associations stay put.
    casks = [
      # Keeps the Mac awake only while an AI agent is working (see
      # home/adrafinil.nix). Requires macOS 26. Adrafinil updates itself in
      # place, so the flake.lock pin is only the floor version.
      "adrafinil"
      "blender"
      "claude"
      "dockdoor"
      "ghostty"
      "google-chrome"
      "monitorcontrol"
      "obs"
      "obsidian"
      "productdevbook/tap/portkiller"
      "raycast"
      "scroll-reverser"
      # Also ships the `orca` CLI. Orca updates itself in place, so the
      # flake.lock pin is only the floor version.
      "stablyai/orca/orca"
      "thebrowsercompany-dia"
      "visual-studio-code"
    ];
  };
}
