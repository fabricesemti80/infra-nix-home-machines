# Nix Package Overrides
# Purpose: Workarounds for selected upstream package checks and Herdr detection.
_: {
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

  # Herdr is installed only on Darwin. Preserve omp's process name there while
  # leaving the Linux package derivation unchanged for apoc's binary cache.
  omp-herdr-fix = _final: prev:
    if prev.stdenv.hostPlatform.isDarwin
    then {
      omp = prev.omp.overrideAttrs (_old: {
        # Herdr cannot recognize the generic CLI path when Bun replaces argv[0].
        postFixup =
          (_old.postFixup or "")
          + ''
            substituteInPlace "$out/bin/omp" \
              --replace-fail 'exec "' 'exec -a omp "'
          '';
      });
    }
    else {};
}
