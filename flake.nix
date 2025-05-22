{
  description = "NixOS and nix-darwin configs for my machines";
  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixOS profiles to optimize settings for different hardware
    hardware.url = "github:nixos/nixos-hardware";

    # Global catppuccin theme
    catppuccin.url = "github:catppuccin/nix";

    # NixOS Spicetify
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nix Darwin (for MacOS machines)
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Homebrew
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    zsh-autosuggestions = {
      url = "github:zsh-users/zsh-autosuggestions";
      flake = false;
    };
    zsh-history-substring-search = {
      url = "github:zsh-users/zsh-history-substring-search";
      flake = false;
    };
  };

  outputs = {
    self,
    catppuccin,
    darwin,
    home-manager,
    nix-homebrew,
    nixpkgs,
    zsh-autosuggestions,
    zsh-history-substring-search,
    ...
  } @ inputs: let
    inherit (self) outputs;

    # Define user configurations
    users = {
      fs = {
        avatar = ./files/avatar/face.png;
        email = "fabrice@fabricesemti.com";
        fullName = "Fabrice Semti";
        gitKey = "YOUR_GIT_KEY";
        name = "fs";
        sshKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBJpVWYmXPpqVmlHdixDR//vdfD+sryvYmpH2Dj1/Otx fabrice@fabricesemti.com"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDl0ivGFV8D/M53/qvRRkfxkKgY3635xDiiLQwFgrWon fabrice@fabricesemti.com"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIX2Y3nmVHNxNCNV+WXHeBEcXFS0XYDnNWxzm9oAIyFa fabrice@fabricesemti.com"
        ];
      };
    };

    # Function for NixOS system configuration
    mkNixosConfiguration = hostname: username:
      nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs outputs hostname;
          userConfig = users.${username};
        };
        modules = [./hosts/${hostname}/configuration.nix];
      };

    # Function for nix-darwin system configuration
    mkDarwinConfiguration = hostname: username:
      darwin.lib.darwinSystem {
        system = "aarch64-darwin";
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
        pkgs = import nixpkgs {inherit system;};
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
      "nixos" = mkNixosConfiguration "nixos" "fs";
    };

    darwinConfigurations = {
      "macvm-fs" = mkDarwinConfiguration "macvm-fs" "fs";
      "macpro-fs" = mkDarwinConfiguration "macpro-fs" "fs";
    };

    homeConfigurations = {
      "fs@nixos" = mkHomeConfiguration "x86_64-linux" "fs" "nixos";
      "fs@macvm-fs" = mkHomeConfiguration "aarch64-darwin" "fs" "macvm-fs";
      "fs@macpro-fs" = mkHomeConfiguration "aarch64-darwin" "fs" "macpro-fs";
    };

    overlays = import ./overlays {inherit inputs;};
  };
}
