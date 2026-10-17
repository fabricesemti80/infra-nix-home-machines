.PHONY: bootstrap-mac install-nix install-nix-darwin darwin-rebuild

HOST ?= $(shell hostname -s)

install-nix:
	@echo "Installing Nix..."
	@curl -fsSL https://nixos.org/nix/install | sh -s -- --daemon --yes
	@echo "Nix installation complete."

install-nix-darwin:
	@echo "Installing nix-darwin..."
	@sudo nix --extra-experimental-features "nix-command flakes" run --inputs-from . darwin#darwin-rebuild -- switch --flake .#$(HOST)
	@echo "nix-darwin installation complete."

darwin-rebuild:
	@echo "Rebuilding darwin configuration..."
	@just darwin-switch $(HOST)
	@echo "Darwin rebuild complete."

bootstrap-mac: install-nix install-nix-darwin
