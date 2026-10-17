# ============================================================================
# System Information
# ============================================================================

# Show current system and home manager configurations
show-config:
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    @echo "📋 Showing current configurations..."
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    @echo ""
    @echo "=== System Information ==="
    @echo "Hostname: {{hostname}}"
    @echo "Darwin Configuration: .#{{hostname}}"
    @echo "Home Manager Configuration: .#fs@{{hostname}}"
    @echo ""
    @echo "=== Darwin System Generations ==="
    @nix profile history --profile /nix/var/nix/profiles/system 2>/dev/null | tail -n 10 || echo "Unable to read Darwin generations"
    @echo ""
    @echo "=== Current System Link ==="
    @ls -l /run/current-system 2>/dev/null || echo "Not available"
    @echo ""
    @echo "=== Home Manager Generations (Last 5) ==="
    @home-manager generations | head -n 5

# ============================================================================
# Maintenance & Cleanup
# ============================================================================

# Cleanup Nix store and old generations locally and on enabled NixOS targets
clean:
    #!/usr/bin/env bash
    set -euo pipefail
    doppler run -- home-manager expire-generations "-30 days"
    doppler run -- nix-collect-garbage --delete-older-than 30d
    failed=0
    for h in {{enabled_nixos_hosts}}; do
      if ! just _clean-nixos-one "$h"; then
        echo "Cleanup failed on $h" >&2
        failed=1
      fi
    done
    exit "$failed"

# Cleanup Nix store and old generations on a single NixOS target.
_clean-nixos-one host:
    #!/usr/bin/env bash
    set -euo pipefail
    target=$(just _nixos-target "{{host}}")
    just _banner 32 clean "{{host}}" "Cleaning Nix store on ${target}"
    ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new "$target" 'sudo nix-collect-garbage --delete-older-than 30d && nix-collect-garbage --delete-older-than 30d && df -h / /nix'


# Upgrade Homebrew packages explicitly, without removing undeclared applications.
brew-update:
    brew update
    brew upgrade
