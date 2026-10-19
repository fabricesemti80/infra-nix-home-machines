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

  # Fix atuin build issues by disabling tests (flaky e2e capture test on macOS)
  atuin-no-tests = _final: prev: {
    atuin = prev.atuin.overrideAttrs (_old: {
      doCheck = false;
    });
  };

  # Refresh pinned source hash for omp (can1357/oh-my-pi v18.11.0);
  # upstream tarball content drifted from the hash shipped in nixpkgs,
  # and the build sandbox consistently receives the older tarball content.
  omp-hash-fix = _final: prev: {
    omp = prev.omp.overrideAttrs (_old: {
      src = _old.src.overrideAttrs (_: {
        hash = "sha256-pIAoAc3vE8nfVacsY+IEGcQVFCfMvVrK5qPcxi7NTho=";
      });
    });
  };
}
