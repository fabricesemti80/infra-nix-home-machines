# Nix Package Overlays
# Purpose: Provides access to stable nixpkgs via pkgs.stable
{inputs, ...}: {
  stable-packages = final: _prev: {
    stable = import inputs.nixpkgs-stable {
      inherit (final) system;
      config.allowUnfree = true;
    };
  };
}
