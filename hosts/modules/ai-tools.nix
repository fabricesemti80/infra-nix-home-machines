# Module: AI Tools (Host-level)
# Purpose: System-wide AI tooling configuration
# Platform: All
# Note: AI tool packages are declared in hosts/modules/packages/system-packages.nix
#       (Nix packages) and hosts/modules/packages/homebrew-packages.nix (macOS casks).
{...}: {
  # Token-saving environment variables for Claude Code.
  # These are host-level because they configure system-installed packages and
  # should apply across all user shells.
  # Uses environment.variables (cross-platform between NixOS and nix-darwin).
  environment.variables = {
    # Disable auto-execution to save tokens on wrong guesses.
    CLAUDE_CODE_SKIP_PERMISSIONS = "1";
    # Prefer compact mode.
    CLAUDE_CODE_COMPACT = "1";
  };
}
