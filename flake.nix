{
  description = "NixOS and nix-darwin configs for my machines";
  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";

    # Encrypted runtime credentials; private age identities stay off-repository.
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
        url = "github:Homebrew/brew/6.0.13";
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
    systems = ["x86_64-linux" "aarch64-darwin"];
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
        modules = [
          ./hosts/${hostname}/configuration.nix
          inputs.sops-nix.nixosModules.sops
          ./hosts/modules/secrets.nix
        ];
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
          inputs.sops-nix.darwinModules.sops
          ./hosts/modules/secrets.nix
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
    nixosConfigurations = {
      "apoc" = mkNixosConfiguration "apoc" "fs";
    };

    darwinConfigurations = {
      "neo" = mkDarwinConfiguration "neo" "fs";
    };

    homeConfigurations = {
      "fs@apoc" = mkHomeConfiguration "aarch64-linux" "fs" "apoc";
      "fs@neo" = mkHomeConfiguration "aarch64-darwin" "fs" "neo";
    };

    overlays = import ./overlays {inherit inputs;};

    # Pre-commit hooks check
    checks = forAllSystems (system: {
      pre-commit-check = pre-commit-hooks.lib.${system}.run {
        src = ./.;
        hooks = {
          # Nix formatting (blocks commits if code isn't formatted)
          alejandra.enable = true;

          sops-ciphertext = {
            enable = true;
            name = "Require encrypted SOPS payloads";
            entry = "${(pkgsFor system).python3.withPackages (ps: [ps.pyyaml])}/bin/python ${./tools/check-secrets.py}";
            files = "^secrets/.*\\.yaml$";
            language = "system";
          };

          sops-ssh-tests = {
            enable = true;
            name = "SOPS and SSH migration tests";
            entry = "${(pkgsFor system).python3.withPackages (ps: [ps.pyyaml])}/bin/python -m unittest discover -s tests -v";
            language = "system";
            pass_filenames = false;
            always_run = true;
            extraPackages = [(pkgsFor system).sops (pkgsFor system).age (pkgsFor system).openssh ((pkgsFor system).python3.withPackages (ps: [ps.pyyaml]))];
          };

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
          alejandra # Nix formatter
          statix # Nix linter
          deadnix # Dead code detector
          nil # Nix LSP
          age
          sops
          openssh
          (python3.withPackages (ps: [ps.pyyaml]))
        ];
      };
    });

    # Formatter for nix fmt
    formatter = forAllSystems (system: (pkgsFor system).alejandra);
  };
}
