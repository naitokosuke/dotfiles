{
  description = "naito's nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    nix-homebrew.inputs.brew-src.follows = "brew-src";

    # Homebrew itself, pinned ahead of nix-homebrew's own brew-src (issue #432).
    # hosts/common/homebrew.nix sets `nix-homebrew.package` from this input so
    # the package name follows the ref below.
    brew-src = {
      url = "github:Homebrew/brew/7.0.1";
      flake = false;
    };

    # brew bundle unconditionally loads the core tap when
    # HOMEBREW_NO_INSTALL_FROM_API is set, so it must be pinned even though
    # no formulae are installed via Homebrew.
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };

    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    homebrew-productdevbook = {
      url = "github:productdevbook/homebrew-tap";
      flake = false;
    };

    homebrew-orca = {
      url = "github:stablyai/homebrew-orca";
      flake = false;
    };

    vscode-settings.url = "github:naitokosuke/vscode-settings";
    vscode-settings.flake = false;

    # Claude Code skills - non-flake input; home/claude.nix readDirs the
    # locked snapshot to discover skill names in pure eval.
    # Resync after adding/removing a skill: push it, then
    #   nix flake update skill-skill-skill
    skill-skill-skill = {
      url = "github:naitokosuke/skill-skill-skill";
      flake = false;
    };

    llm-agents.url = "github:numtide/llm-agents.nix";
    llm-agents.inputs.nixpkgs.follows = "nixpkgs";
    llm-agents.inputs.treefmt-nix.follows = "treefmt-nix";

    mcp-servers-nix.url = "github:natsukium/mcp-servers-nix";
    mcp-servers-nix.inputs.nixpkgs.follows = "nixpkgs";

    nu-scripts = {
      url = "github:nushell/nu_scripts";
      flake = false;
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      nix-darwin,
      home-manager,
      treefmt-nix,
      nix-homebrew,
      llm-agents,
      ...
    }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs {
        localSystem = system;
      };

      hosts = [
        "Mac-big"
        "Macbook-heavy"
      ];

      mkDarwinConfig =
        hostName:
        nix-darwin.lib.darwinSystem {
          specialArgs = {
            inherit inputs;
          };
          modules = [
            ./modules/naitokosuke
            (
              { config, ... }:
              {
                networking.hostName = hostName;
                networking.computerName = hostName;
                system.primaryUser = config.naitokosuke.username;
                nixpkgs.config.allowUnfree = true;
                nixpkgs.hostPlatform = system;
                nixpkgs.overlays = [
                  # Custom packages tracked by nvfetcher (./pkgs, issue #342)
                  (final: _: import ./pkgs { pkgs = final; })
                  llm-agents.overlays.shared-nixpkgs
                ];
              }
            )
            home-manager.darwinModules.home-manager
            nix-homebrew.darwinModules.nix-homebrew
            ./hosts/common
            ./hosts/${hostName}
          ];
        };
    in
    {
      darwinConfigurations = nixpkgs.lib.genAttrs hosts mkDarwinConfig;

      packages.${system} = import ./pkgs { inherit pkgs; };

      formatter.${system} = treefmt-nix.lib.mkWrapper pkgs {
        projectRootFile = "flake.nix";
        programs.nixfmt.enable = true;
      };
    };
}
