# Justfile for Nix Darwin and Home Manager system management

# Determine the hostname dynamically
hostname := `hostname`

# Default recipe: Shows available commands
default:
    @just --list

# Switch Nix Darwin configuration dynamically
darwin-switch:
    sudo nix run nix-darwin -- switch --flake .#{{hostname}}

# Switch Nix Darwin configuration for macvm-fs
darwin-switch-macvm-fs:
    sudo nix run nix-darwin -- switch --flake .#macvm-fs

# Switch Home Manager configuration dynamically
home-switch:
    home-manager switch --flake .#fs@{{hostname}}

# Switch Home Manager configuration for macvm-fs
home-switch-macvm-fs:
    home-manager switch --flake .#fs@macvm-fs

# Update flake inputs
update:
    nix flake update

# Cleanup Nix store and generations
clean:
    nix-collect-garbage -d
    home-manager expire-generations "-7 days"

# Build Darwin configuration dynamically without switching
darwin-build:
    nix run nix-darwin -- build --flake .#{{hostname}}

# Build Darwin configuration for macvm-fs without switching
darwin-build-macvm-fs:
    nix run nix-darwin -- build --flake .#macvm-fs

# Build Home Manager configuration dynamically without switching
home-build:
    home-manager build --flake .#fs@{{hostname}}

# Build Home Manager configuration for macvm-fs without switching
home-build-macvm-fs:
    home-manager build --flake .#fs@macvm-fs

# Show current system and home manager configurations
show-config:
    #!/usr/bin/env bash
    echo "=== Nix Darwin Configuration ==="
    darwin-rebuild --show-trace show-configuration
    echo -e "\n=== Home Manager Configuration ==="
    home-manager configuration

# Verify flake
verify-flake:
    nix flake check

# Open nix repl with current flake
repl:
    nix repl .#

# Quick system and home update dynamically (combination of update and switch commands)
quick-update: update darwin-switch home-switch

# Quick system and home update for macvm-fs
quick-update-macvm-fs: update darwin-switch-macvm-fs home-switch-macvm-fs

