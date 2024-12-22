# Justfile for Nix Darwin and Home Manager system management

# Default recipe (shows available commands)
default:
    @just --list

# Define the hostname dynamically
hostname := `hostname`

# Install Nix
install-nix:
    @echo "Installing Nix..."
    sudo curl -L https://nixos.org/nix/install | sh -s -- --daemon --yes
    @echo "Nix installation complete."

# Install nix-darwin
install-nix-darwin:
    @echo "Installing nix-darwin..."
    nix run nix-darwin --extra-experimental-features "nix-command flakes" -- switch --flake .#{{hostname}}
    @echo "nix-darwin installation complete."

# Bootstrap macOS setup
bootstrap-mac: install-nix install-nix-darwin
    @echo "Bootstrap process complete!"

# Task: Switch Nix Darwin configuration
darwin-switch:
    nix run nix-darwin -- switch --flake .#macvm-fs

# Switch Home Manager configuration
home-switch:
    home-manager switch --flake .#fs@macvm-fs

# Update flake inputs
update:
    nix flake update

# Cleanup Nix store and generations
clean:
    nix-collect-garbage -d
    home-manager expire-generations "-7 days"

# Build Darwin configuration without switching
darwin-build:
    nix run nix-darwin -- build --flake .#macvm-fs

# Task: Rebuild darwin configuration
darwin-rebuild:
    @echo "Rebuilding darwin configuration..."
    darwin-rebuild switch --flake .#{{hostname}}
    @echo "Darwin rebuild complete."

# Build Home Manager configuration without switching
home-build:
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

# Quick system and home update (combination of update and switch commands)
quick-update: update darwin-switch home-switch
