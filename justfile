# Justfile for Nix Darwin and Home Manager system management

# Default recipe (shows available commands)
default:
    @just --list

# Switch Nix Darwin configuration
darwin-switch:
    nix run nix-darwin -- switch --flake .#fabrice-mac

# Switch Home Manager configuration
home-switch:
    home-manager switch --flake .#fs@fabrice-mac

# Update flake inputs
update:
    nix flake update

# Cleanup Nix store and generations
clean:
    nix-collect-garbage -d
    home-manager expire-generations "-7 days"

# Build Darwin configuration without switching
darwin-build:
    nix run nix-darwin -- build --flake .#fabrice-mac

# Build Home Manager configuration without switching
home-build:
    home-manager build --flake .#fs@fabrice-mac

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

# Quick system and home update (combination of update and switch commands)
quick-update: update darwin-switch home-switch