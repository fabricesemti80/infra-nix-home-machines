# Nix Package Overrides
# Purpose: Provides access to stable nixpkgs via pkgs.stable
{inputs, ...}: {
  stable-packages = final: _prev: {
    stable = import inputs.nixpkgs-stable {
      localSystem = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  };

  # Fix fish build issues by disabling tests
  fish-no-tests = _final: prev: {
    fish = prev.fish.overrideAttrs (_old: {
      doCheck = false;
    });
  };

  # Fix direnv build issues by disabling tests (often hangs on macOS)
  direnv-no-tests = _final: prev: {
    direnv = prev.direnv.overrideAttrs (_old: {
      doCheck = false;
    });
  };
}
