{
  description = "NixOS and nix-darwin configs for my machines";
  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Herdr terminal workspace (keep upstream's locked build dependencies)
    herdr.url = "github:herdrdev/herdr/v0.9.5";

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixOS profiles to optimize settings for different hardware
    hardware.url = "github:nixos/nixos-hardware";

    # Declarative disk partitioning for NixOS VM hosts
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Global catppuccin theme
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nix Darwin (for MacOS machines)
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Homebrew
    nix-homebrew = {
      # ponytail: pinned, c11cccf shim breaks brew (missing HOMEBREW_ORIGINAL_BREW_FILE
      # export) - unpin when https://github.com/zhaofengli/nix-homebrew/issues/187 fixed
      url = "github:zhaofengli/nix-homebrew/09a921d0181146cf6163ec2cc1db7b6fd539a885";
      inputs.brew-src = {
        url = "github:Homebrew/brew/6.0.22";
        flake = false;
      };
    };

    # Zsh plugins
    zsh-autosuggestions = {
      url = "github:zsh-users/zsh-autosuggestions";
      flake = false;
    };
    zsh-history-substring-search = {
      url = "github:zsh-users/zsh-history-substring-search";
      flake = false;
    };

    # Pre-commit hooks
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    catppuccin,
    darwin,
    home-manager,
    nix-homebrew,
    nixpkgs,
    pre-commit-hooks,
    ...
  } @ inputs: let
    inherit (self) outputs;

    # Systems to support
    systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];
    inventory = builtins.fromJSON (builtins.readFile ./inventory.json);
    forAllSystems = nixpkgs.lib.genAttrs systems;
    pkgsFor = system: import nixpkgs {localSystem = system;};

    # Define user configurations by importing from separate files for modularity and privacy
    users = {
      fs = import ./users/fs.nix;
    };

    # Function for NixOS system configuration
    mkNixosConfiguration = hostname: username: let
      userConfig = users.${username};
    in
      nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs outputs hostname userConfig;
        };
        modules = [./hosts/${hostname}/configuration.nix];
      };

    # Function for nix-darwin system configuration
    mkDarwinConfiguration = hostname: username:
      darwin.lib.darwinSystem {
        specialArgs = {
          inherit inputs outputs hostname;
          userConfig = users.${username};
        };
        modules = [
          ./hosts/${hostname}/configuration.nix
          home-manager.darwinModules.home-manager
          nix-homebrew.darwinModules.nix-homebrew
        ];
      };

    # Function for Home Manager configuration
    mkHomeConfiguration = system: username: hostname:
      home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {localSystem = system;};
        extraSpecialArgs = {
          inherit inputs outputs;
          userConfig = users.${username};
        };
        modules = [
          ./home/${username}/${hostname}.nix
          catppuccin.homeModules.catppuccin
        ];
      };
  in {
    nixosConfigurations =
      nixpkgs.lib.mapAttrs
      (hostname: host: mkNixosConfiguration hostname host.user)
      (nixpkgs.lib.filterAttrs (_: host: host.lane == "nixos") inventory);

    darwinConfigurations =
      nixpkgs.lib.mapAttrs
      (hostname: host: mkDarwinConfiguration hostname host.user)
      (nixpkgs.lib.filterAttrs (_: host: host.lane == "darwin") inventory);

    homeConfigurations =
      nixpkgs.lib.mapAttrs'
      (hostname: host:
        nixpkgs.lib.nameValuePair "${host.user}@${hostname}"
        (mkHomeConfiguration host.platform host.user hostname))
      inventory;

    overlays = import ./overlays {inherit inputs;};

    # Pre-commit hooks check
    checks = forAllSystems (system: {
      pre-commit-check = pre-commit-hooks.lib.${system}.run {
        src = ./.;
        hooks = {
          # Nix formatting (blocks commits if code isn't formatted)
          alejandra.enable = true;
          statix.enable = true;
          deadnix.enable = true;

          # YAML validation
          check-yaml.enable = true;

          # TOML validation
          check-toml.enable = true;

          # JSON validation
          check-json.enable = true;
        };
      };
    });

    # Development shells with pre-commit
    devShells = forAllSystems (system: let
      pkgs = pkgsFor system;
    in {
      default = pkgs.mkShell {
        inherit (self.checks.${system}.pre-commit-check) shellHook;
        buildInputs = self.checks.${system}.pre-commit-check.enabledPackages;
        packages = with pkgs; [
          alejandra # Nix formatter — https://github.com/kamadorueda/alejandra
          statix # Nix linter — https://github.com/molybdenumsoftware/statix
          deadnix # Dead code detector — https://github.com/astro/deadnix
          nix-output-monitor # Summarize Nix builds and keep failed derivations visible.
          nil # Nix LSP — https://github.com/oxalica/nil
        ];
      };
    });

    # Formatter for nix fmt
    formatter = forAllSystems (system: (pkgsFor system).alejandra);
  };
}
