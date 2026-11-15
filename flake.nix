# The single source of truth for both Macs: every upstream input is pinned
# here, and `darwinConfigurations` is assembled per host from the same pinned
# set, so a given flake.lock evaluates to the same system every time.
{
  description = "naito's nix-darwin system flake";

  ## Inputs
  # Inputs that depend on nixpkgs `follow` this one, so everything ships one
  # package set. The `flake = false` inputs are locked source snapshots read
  # at eval time: Homebrew itself and its taps, the VS Code settings and the
  # Claude Code skills. `llm-agents` supplies Claude Code and `mcp-servers-nix`
  # the MCP module.
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:nix-darwin/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    nix-homebrew.inputs.brew-src.follows = "brew-src";

    # Homebrew itself, pinned ahead of nix-homebrew's own brew-src (issue #432).
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

    skill-skill-skill = {
      url = "github:naitokosuke/skill-skill-skill";
      flake = false;
    };

    llm-agents.url = "github:numtide/llm-agents.nix";
    llm-agents.inputs.nixpkgs.follows = "nixpkgs";
    llm-agents.inputs.treefmt-nix.follows = "treefmt-nix";

    mcp-servers-nix.url = "github:natsukium/mcp-servers-nix";
    mcp-servers-nix.inputs.nixpkgs.follows = "nixpkgs";
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

      # The single entry into ./pkgs, used by both the overlay and the
      # `packages` output below.
      customPackages = final: import ./pkgs { pkgs = final; };

      nixpkgsConfig = {
        # Named one by one, so a new unfree dependency fails evaluation instead
        # of slipping in.
        allowUnfreePredicate =
          pkg:
          builtins.elem (nixpkgs.lib.getName pkg) [
            "input-fonts"
          ];
        input-fonts.acceptLicense = true;
      };

      ## Overlays
      # The custom packages sit under `pkgs.naitokosuke` rather than at the top
      # level, so one can never shadow a nixpkgs attribute of the same name
      # (#545). The same set is the flake's `packages` output, so
      # `nix build .#frog` works standalone.
      overlays = [
        (final: _: { naitokosuke = customPackages final; })
        llm-agents.overlays.shared-nixpkgs
      ];

      ## One nixpkgs instance
      # Imported once, with the overlays and the nixpkgs config, and used by
      # everything: the hosts take it through `nixpkgs.pkgs` and the flake's
      # own outputs are built from it (#554). A custom package therefore builds
      # the same way through `nix build .#<pkg>` as through
      # `darwin-rebuild switch`.
      pkgs = import nixpkgs {
        localSystem = system;
        config = nixpkgsConfig;
        inherit overlays;
      };

      hosts = [
        "Mac-big"
        "Macbook-heavy"
      ];

      ## mkDarwinConfig
      # One `darwinSystem` per host. `specialArgs` hands the flake `inputs` to
      # every module, and the inline module gives each host the `pkgs` above
      # through `nixpkgs.pkgs`, with `system.primaryUser` read from
      # `config.naitokosuke.username`. `./modules/naitokosuke` loads first,
      # then the home-manager and nix-homebrew modules, `hosts/common` and
      # `hosts/<hostName>`. Adding a Mac is one entry in `hosts` plus a
      # `hosts/<host>/default.nix`.
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
                nixpkgs.pkgs = pkgs;
              }
            )
            home-manager.darwinModules.home-manager
            nix-homebrew.darwinModules.nix-homebrew
            ./hosts/common
            ./hosts/${hostName}
          ];
        };
      darwinConfigurations = nixpkgs.lib.genAttrs hosts mkDarwinConfig;

      ## Formatter
      # `nix fmt` runs nixfmt through treefmt-nix, with flake.nix marking the
      # project root.
      treefmtEval = treefmt-nix.lib.evalModule pkgs {
        projectRootFile = "flake.nix";
        programs.nixfmt.enable = true;
        # Generated by nvfetcher, and not always the way nixfmt would write it.
        settings.global.excludes = [ "pkgs/_sources/*" ];
      };
    in
    {
      inherit darwinConfigurations;

      packages.${system} = customPackages pkgs;

      formatter.${system} = treefmtEval.config.build.wrapper;

      ## Docs data
      # The facts the walkthrough site in docs/ shows (casks, package versions,
      # enabled programs, locked inputs, options), evaluated rather than
      # restated in prose (#612). The site reads it as JSON:
      #   nix eval --json .#docsData
      docsData = import ./docs/facts.nix {
        inherit (nixpkgs) lib;
        inherit darwinConfigurations;
        inherit (inputs) self;
        packages = inputs.self.packages.${system};
      };

      ## Checks
      # `nix flake check` on its own only notices that `darwinConfigurations`
      # exists, so the hosts and the custom packages are listed here to be
      # built, along with the formatting check, the deletion guard's `bun test`
      # suite, and a check that the JSON tool AGENTS.md rules out has not come
      # back. The check workflow runs this on every pull request, and the
      # nvfetcher workflow before proposing a bump.
      checks.${system} =
        nixpkgs.lib.mapAttrs' (
          name: host: nixpkgs.lib.nameValuePair "host-${name}" host.config.system.build.toplevel
        ) darwinConfigurations
        // nixpkgs.lib.mapAttrs' (
          name: nixpkgs.lib.nameValuePair "package-${name}"
        ) inputs.self.packages.${system}
        // {
          formatting = treefmtEval.config.build.check inputs.self;

          claude-rm-guard =
            pkgs.runCommand "claude-rm-guard-test"
              {
                nativeBuildInputs = [
                  pkgs.bun
                  pkgs.shfmt
                ];
              }
              ''
                cd ${./home/claude-rm-guard}
                HOME=$TMPDIR bun test
                touch $out
              '';

          # See AGENTS.md. The pattern is spelled so this file does not match
          # itself.
          no-json-query-tool =
            pkgs.runCommand "no-json-query-tool" { nativeBuildInputs = [ pkgs.ripgrep ]; }
              ''
                if rg --hidden --line-number --glob '!AGENTS.md' '\bj[q]\b' ${inputs.self}; then
                  echo "This repository does not use the tool named above; see AGENTS.md." >&2
                  exit 1
                fi
                touch $out
              '';
        };
    };
}
