# Justfile for Nix Darwin and Home Manager system management

# Determine the hostname dynamically
hostname := `hostname`
enabled_darwin_hosts := "neo"
enabled_nixos_hosts := "morpheus apoc trinity"

# All known host names in the flake (used to validate explicit host filters).
valid_hosts := "neo trinity apoc morpheus"

# Per-lane host sets: every host that can be deployed in a given lane.
darwin_hosts := "neo"
nixos_hosts := "morpheus apoc trinity"

# Default recipe: Shows available commands
default:
    @just --list

# Print a colored section banner for long-running recipes.
_banner color lane target action:
    @printf '\n\033[1;{{color}}m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m\n'
    @printf '\033[1;{{color}}m%s :: %s\033[0m\n' "{{lane}}" "{{target}}"
    @printf '\033[{{color}}m%s\033[0m\n' "{{action}}"
    @printf '\033[1;{{color}}m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m\n'

# Print a non-fatal skip message for aggregate recipes.
_skip color lane target reason:
    @printf '\n\033[1;{{color}}m%s :: %s\033[0m\n' "{{lane}}" "{{target}}"
    @printf '\033[1;{{color}}mSkipping: %s\033[0m\n' "{{reason}}"

# Validate that every host in a comma-list filter is a known host. "all" is always valid.
_validate-hosts filter:
    #!/usr/bin/env bash
    set -euo pipefail
    filter="{{filter}}"
    if [ "$filter" = "all" ]; then
        exit 0
    fi
    while IFS= read -r h; do
        h=$(echo "$h" | xargs)
        [ -z "$h" ] && continue
        if ! echo "{{valid_hosts}}" | tr ' ' '\n' | grep -qx "$h"; then
            echo "Unknown host '$h'. Valid hosts: {{valid_hosts}}" >&2
            exit 1
        fi
    done < <(echo "$filter" | tr ',' '\n')

# Resolve a host filter to the hosts a per-lane command should process.
# "all" → the lane's enabled set. Comma-list → entries that are valid for the lane
# (errors on entries that belong to other lanes so direct calls fail fast).
# Echoes one host per line.
_resolve-hosts filter enabled lane_hosts:
    #!/usr/bin/env bash
    set -euo pipefail
    filter="{{filter}}"
    enabled="{{enabled}}"
    lane_hosts="{{lane_hosts}}"
    if [ "$filter" = "all" ]; then
        echo "$enabled" | tr ' ' '\n'
    else
        while IFS= read -r h; do
            h=$(echo "$h" | xargs)
            [ -z "$h" ] && continue
            if ! echo "$lane_hosts" | tr ' ' '\n' | grep -qx "$h"; then
                echo "Host '$h' is not valid for this lane. Valid: $lane_hosts" >&2
                exit 1
            fi
            echo "$h"
        done < <(echo "$filter" | tr ',' '\n')
    fi

# Build a comma-list of hosts to process for a lane, given a user filter.
# "all" → the lane's enabled set joined with commas. Comma-list → entries valid
# for the lane, joined with commas (silently drops cross-lane entries).
# Echoes "" if the lane has nothing to do.
_quick-update-filter filter enabled lane_hosts:
    #!/usr/bin/env bash
    set -euo pipefail
    filter="{{filter}}"
    enabled="{{enabled}}"
    lane_hosts="{{lane_hosts}}"
    if [ "$filter" = "all" ]; then
        echo "$enabled" | tr ' ' '\n' | paste -sd ',' -
        exit 0
    fi
    echo "$filter" | tr ',' '\n' | while IFS= read -r h; do
        h=$(echo "$h" | xargs)
        [ -z "$h" ] && continue
        if echo "$lane_hosts" | tr ' ' '\n' | grep -qx "$h"; then
            echo "$h"
        fi
    done | paste -sd ',' -

# ============================================================================
# Quick Update Commands
# ============================================================================

# Update flake inputs, then switch every enabled deployment lane. Pass a host or
# comma-separated host list (e.g. `quick-update neo` or `quick-update neo,morpheus`)
# to limit the scope; lanes that have no matching hosts are skipped.
quick-update hosts="all":
    #!/usr/bin/env bash
    set -euo pipefail
    just _validate-hosts "{{hosts}}"
    just update

    # Build a per-lane filter (silently dropping cross-lane entries) and call each lane
    # that has at least one host to process.
    darwin_filter=$(just _quick-update-filter "{{hosts}}" "{{enabled_darwin_hosts}}" "{{darwin_hosts}}")
    nixos_filter=$(just _quick-update-filter "{{hosts}}" "{{enabled_nixos_hosts}}" "{{nixos_hosts}}")

    if [ -n "$darwin_filter" ]; then just darwin-switch "$darwin_filter"; fi
    if [ -n "$nixos_filter" ]; then just nixos-switch "$nixos_filter"; fi

# Update flake inputs, then switch one enabled deployment lane. Pass a host or
# comma-separated host list to limit the scope within the lane.
quick-update-lane lane hosts="all":
    #!/usr/bin/env bash
    set -euo pipefail
    just _validate-hosts "{{hosts}}"
    just update
    case "{{lane}}" in
      darwin)
        filter=$(just _quick-update-filter "{{hosts}}" "{{enabled_darwin_hosts}}" "{{darwin_hosts}}")
        if [ -n "$filter" ]; then just darwin-switch "$filter"; fi
        ;;
      nixos)
        filter=$(just _quick-update-filter "{{hosts}}" "{{enabled_nixos_hosts}}" "{{nixos_hosts}}")
        if [ -n "$filter" ]; then just nixos-switch "$filter"; fi
        ;;
      *)
        echo "Unknown lane '{{lane}}'. Expected one of: darwin, nixos" >&2
        exit 1
        ;;
    esac

# ============================================================================
# Flake Management
# ============================================================================

# Update flake inputs
update:
    @just _banner 33 flake inputs "Updating flake inputs"
    doppler run -- nix flake update

# Verify flake configuration
verify-flake:
    @just _banner 33 flake check "Verifying flake configuration"
    doppler run -- nix flake check

# Open nix repl with current flake
repl:
    @just _banner 33 flake repl "Opening Nix REPL"
    doppler run -- nix repl .#

# ============================================================================
# Darwin (macOS System) Management
# ============================================================================

# Switch nix-darwin and Home Manager on selected Macs ("all" or comma-list).
darwin-switch host="all":
    #!/usr/bin/env bash
    set -euo pipefail
    just _validate-hosts "{{host}}"
    while IFS= read -r h; do
      if ! just _darwin-switch-one "$h"; then
        just _skip 36 darwin "$h" "switch failed"
      fi
    done < <(just _resolve-hosts "{{host}}" "{{enabled_darwin_hosts}}" "{{darwin_hosts}}")

# Switch nix-darwin and Home Manager on a single Mac.
_darwin-switch-one host:
    #!/usr/bin/env bash
    set -euo pipefail
    just _banner 36 darwin "{{host}}" "Switching nix-darwin configuration"
    if command -v brew >/dev/null 2>&1; then
      for trust_target in nikitabobko/tap nikitabobko/tap/aerospace powershell/tap adembc/tap manaflow-ai/cmux; do
        brew trust "$trust_target" 2>/dev/null || true
      done
    fi
    doppler run -- sudo nix run nix-darwin -- switch --flake .#{{host}}
    just _darwin-home-switch-one "{{host}}"

# Switch Home Manager on selected Macs ("all" or comma-list).
darwin-home-switch host="all":
    #!/usr/bin/env bash
    set -euo pipefail
    just _validate-hosts "{{host}}"
    while IFS= read -r h; do
      if ! just _darwin-home-switch-one "$h"; then
        just _skip 34 home "fs@$h" "Home Manager switch failed"
      fi
    done < <(just _resolve-hosts "{{host}}" "{{enabled_darwin_hosts}}" "{{darwin_hosts}}")

# Switch Home Manager on a single Mac.
_darwin-home-switch-one host:
    #!/usr/bin/env bash
    set -euo pipefail
    just _banner 34 home "fs@{{host}}" "Switching Home Manager configuration"
    doppler run -- home-manager switch --flake .#fs@{{host}}

# Build nix-darwin and Home Manager on selected Macs ("all" or comma-list).
darwin-build host="all":
    #!/usr/bin/env bash
    set -euo pipefail
    just _validate-hosts "{{host}}"
    while IFS= read -r h; do
      if ! just _darwin-build-one "$h"; then
        just _skip 36 darwin "$h" "build failed"
      fi
    done < <(just _resolve-hosts "{{host}}" "{{enabled_darwin_hosts}}" "{{darwin_hosts}}")

# Build nix-darwin and Home Manager on a single Mac.
_darwin-build-one host:
    #!/usr/bin/env bash
    set -euo pipefail
    just _banner 36 darwin "{{host}}" "Building nix-darwin configuration"
    doppler run -- nix run nix-darwin -- build --flake .#{{host}}
    just _darwin-home-build-one "{{host}}"

# Build Home Manager on selected Macs ("all" or comma-list).
darwin-home-build host="all":
    #!/usr/bin/env bash
    set -euo pipefail
    just _validate-hosts "{{host}}"
    while IFS= read -r h; do
      if ! just _darwin-home-build-one "$h"; then
        just _skip 34 home "fs@$h" "Home Manager build failed"
      fi
    done < <(just _resolve-hosts "{{host}}" "{{enabled_darwin_hosts}}" "{{darwin_hosts}}")

# Build Home Manager on a single Mac.
_darwin-home-build-one host:
    #!/usr/bin/env bash
    set -euo pipefail
    just _banner 34 home "fs@{{host}}" "Building Home Manager configuration"
    doppler run -- home-manager build --flake .#fs@{{host}}

# Compatibility alias for the old explicit neo command.
darwin-switch-neo:
    just darwin-switch neo

# Compatibility alias for the old explicit neo home command.
home-switch-neo:
    just darwin-home-switch neo

# ============================================================================
# Physical NixOS Host Management
# ============================================================================

# Resolve SSH target for a physical NixOS host.
_nixos-target host:
    #!/usr/bin/env bash
    set -euo pipefail
    case "{{host}}" in
      morpheus)
        echo "root@10.0.40.19"
        ;;
      apoc)
        echo "fs@10.211.55.8"
        ;;
      trinity)
        echo "fs@10.0.40.61"
        ;;
      *)
        echo "No physical NixOS target configured for '{{host}}'" >&2
        exit 1
        ;;
    esac

# Resolve user SSH target for a physical NixOS host.
_nixos-home-target host:
    #!/usr/bin/env bash
    set -euo pipefail
    case "{{host}}" in
      morpheus)
        echo "fs@10.0.40.19"
        ;;
      apoc)
        echo "fs@10.211.55.8"
        ;;
      trinity)
        echo "fs@10.0.40.61"
        ;;
      *)
        echo "No physical NixOS Home Manager target configured for '{{host}}'" >&2
        exit 1
        ;;
    esac

# Verify a physical NixOS host is reachable before starting a remote build or switch.
_nixos-check-ssh host target:
    #!/usr/bin/env bash
    set -euo pipefail
    if ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no "{{target}}" true 2>&1; then
      exit 0
    fi

    cat >&2 <<'EOF'
    Cannot reach physical NixOS host {{host}} at {{target}} over SSH.

    Check that this machine is on the same LAN/VPN as the server, or that the
    server is already reachable through Tailscale. For morpheus, the direct LAN
    target is 10.0.40.19.
    EOF
    exit 1

# Build NixOS on selected physical hosts ("all" or comma-list).
nixos-build host="all":
    #!/usr/bin/env bash
    set -euo pipefail
    just _validate-hosts "{{host}}"
    while IFS= read -r h; do
      target=$(just _nixos-target "$h")
      if ! ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$target" true 2>&1; then
        just _skip 32 nixos "$h" "host is offline (SSH unreachable)"
        continue
      fi
      if ! just _nixos-build-one "$h"; then
        just _skip 32 nixos "$h" "build failed"
      fi
    done < <(just _resolve-hosts "{{host}}" "{{enabled_nixos_hosts}}" "{{nixos_hosts}}")

# Build NixOS on a single physical host.
_nixos-build-one host:
    #!/usr/bin/env bash
    set -euo pipefail
    target=$(just _nixos-target "{{host}}")
    just _nixos-check-ssh "{{host}}" "$target"
    just _banner 32 nixos "{{host}}" "Building physical host on ${target}"
    export NIX_SSHOPTS="-o StrictHostKeyChecking=no"
    nix run nixpkgs#nixos-rebuild -- build --flake .#{{host}} --target-host "$target" --build-host "$target" --no-reexec
    just _nixos-home-build-one "{{host}}"

# Switch NixOS on selected physical hosts ("all" or comma-list).
nixos-switch host="all":
    #!/usr/bin/env bash
    set -euo pipefail
    just _validate-hosts "{{host}}"
    while IFS= read -r h; do
      target=$(just _nixos-target "$h")
      if ! ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$target" true 2>&1; then
        just _skip 32 nixos "$h" "host is offline (SSH unreachable)"
        continue
      fi
      if ! just _nixos-switch-one "$h"; then
        just _skip 32 nixos "$h" "switch failed"
      fi
    done < <(just _resolve-hosts "{{host}}" "{{enabled_nixos_hosts}}" "{{nixos_hosts}}")

# Push deploy-time secrets from 1Password to a NixOS host before switching.
_nixos-push-secrets host target:
    #!/usr/bin/env bash
    set -euo pipefail
    case "{{host}}" in
      trinity|morpheus)
        if command -v op >/dev/null 2>&1; then
          auth_key=$(op read "op://iac/tailscale-key-server-container/credential")
          printf '%s' "$auth_key" | ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "{{target}}" \
            'sudo mkdir -p /var/lib/tailscale && sudo tee /var/lib/tailscale/tailscale-authkey > /dev/null && sudo chmod 600 /var/lib/tailscale/tailscale-authkey && sudo chown root:root /var/lib/tailscale/tailscale-authkey'
        else
          echo "1Password CLI (op) not found; skipping Tailscale secret push" >&2
        fi
        ;;
      *)
        ;;
    esac
    case "{{host}}" in
      trinity)
        if ! command -v op >/dev/null 2>&1; then
          echo "1Password CLI (op) not found; skipping DockTail secret push" >&2
        else
          client_id=$(op read "op://iac/tailscale-oauth/client_id")
          client_secret=$(op read "op://iac/tailscale-oauth/client_secret")
          ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "{{target}}" \
            "sudo mkdir -p /var/lib/docktail && printf '%s\\n' 'TAILSCALE_OAUTH_CLIENT_ID=${client_id}' 'TAILSCALE_OAUTH_CLIENT_SECRET=${client_secret}' | sudo tee /var/lib/docktail/env > /dev/null && sudo chmod 600 /var/lib/docktail/env && sudo chown root:root /var/lib/docktail/env"
        fi

        # Seed Portainer data from morpheus once, preserving the existing password.
        morpheus_target=$(just _nixos-target morpheus)
        if ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$morpheus_target" true 2>&1; then
          ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "{{target}}" \
            'if [ ! -f /var/lib/portainer-data/portainer.db ]; then sudo mkdir -p /var/lib/portainer-data && sudo tar -xzf - -C /var/lib/portainer-data; else cat > /dev/null; fi' \
            < <(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$morpheus_target" 'cat /tmp/portainer_data.tar.gz')
        else
          echo "Morpheus is offline; skipping Portainer data seed" >&2
        fi
        ;;
      *)
        ;;
    esac

# Switch NixOS on a single physical host.
_nixos-switch-one host:
    #!/usr/bin/env bash
    set -euo pipefail
    target=$(just _nixos-target "{{host}}")
    just _nixos-check-ssh "{{host}}" "$target"
    just _banner 32 nixos "{{host}}" "Switching physical host on ${target}"
    just _nixos-push-secrets "{{host}}" "$target"
    export NIX_SSHOPTS="-o StrictHostKeyChecking=no"
    nix run nixpkgs#nixos-rebuild -- switch --flake .#{{host}} --target-host "$target" --build-host "$target" --sudo --no-reexec --fast
    just _nixos-home-switch-one "{{host}}"

# Build Home Manager on selected physical NixOS hosts ("all" or comma-list).
nixos-home-build host="all":
    #!/usr/bin/env bash
    set -euo pipefail
    just _validate-hosts "{{host}}"
    while IFS= read -r h; do
      target=$(just _nixos-target "$h")
      if ! ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$target" true 2>&1; then
        just _skip 34 home "fs@$h" "host is offline (SSH unreachable)"
        continue
      fi
      if ! just _nixos-home-build-one "$h"; then
        just _skip 34 home "fs@$h" "Home Manager build failed"
      fi
    done < <(just _resolve-hosts "{{host}}" "{{enabled_nixos_hosts}}" "{{nixos_hosts}}")

# Build Home Manager activation package on a single physical host.
_nixos-home-build-one host:
    #!/usr/bin/env bash
    set -euo pipefail
    root_target=$(just _nixos-target "{{host}}")
    just _nixos-check-ssh "{{host}}" "$root_target"
    just _banner 34 home "fs@{{host}}" "Building Home Manager activation package on ${root_target}"
    flake_path=$(nix flake archive --to "ssh://${root_target}" --json | jq -r .path)
    ssh -o StrictHostKeyChecking=no "$root_target" \
      "nix build --extra-experimental-features 'nix-command flakes' --print-out-paths --no-link '${flake_path}#homeConfigurations.\"fs@{{host}}\".activationPackage'"

# Switch Home Manager on selected physical NixOS hosts ("all" or comma-list).
nixos-home-switch host="all":
    #!/usr/bin/env bash
    set -euo pipefail
    just _validate-hosts "{{host}}"
    while IFS= read -r h; do
      root_target=$(just _nixos-target "$h")
      user_target=$(just _nixos-home-target "$h")
      if ! ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$root_target" true 2>&1; then
        just _skip 34 home "fs@$h" "host is offline (root SSH unreachable)"
        continue
      fi
      if ! ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$user_target" true 2>&1; then
        just _skip 34 home "fs@$h" "host is offline (user SSH unreachable)"
        continue
      fi
      if ! just _nixos-home-switch-one "$h"; then
        just _skip 34 home "fs@$h" "Home Manager switch failed"
      fi
    done < <(just _resolve-hosts "{{host}}" "{{enabled_nixos_hosts}}" "{{nixos_hosts}}")

# Switch Home Manager on a single physical host.
_nixos-home-switch-one host:
    #!/usr/bin/env bash
    set -euo pipefail
    root_target=$(just _nixos-target "{{host}}")
    user_target=$(just _nixos-home-target "{{host}}")
    just _nixos-check-ssh "{{host}}" "$root_target"
    just _nixos-check-ssh "{{host}}" "$user_target"
    just _banner 34 home "fs@{{host}}" "Switching Home Manager on ${user_target}"
    flake_path=$(nix flake archive --to "ssh://${root_target}" --json | jq -r .path)
    out=$(ssh -o StrictHostKeyChecking=no "$root_target" \
      "nix build --extra-experimental-features 'nix-command flakes' --print-out-paths --no-link '${flake_path}#homeConfigurations.\"fs@{{host}}\".activationPackage'")
    ssh -o StrictHostKeyChecking=no "$user_target" "$out/activate"

# Compatibility alias for switching all enabled physical NixOS hosts.
nixos-switch-all:
    just nixos-switch

# Compatibility alias for building all enabled physical NixOS hosts.
nixos-build-all:
    just nixos-build

# Compatibility alias for switching Home Manager on all enabled physical NixOS hosts.
nixos-home-switch-all:
    just nixos-home-switch

# Compatibility alias for building Home Manager on all enabled physical NixOS hosts.
nixos-home-build-all:
    just nixos-home-build

# ============================================================================
# Home Manager (User Environment) Management
# ============================================================================

# Switch Home Manager for the current local host, or pass a host explicitly.
home-switch host="current":
    #!/usr/bin/env bash
    set -euo pipefail
    target="{{host}}"
    if [ "$target" = "current" ]; then
      target="{{hostname}}"
    fi
    just _validate-hosts "$target"
    if echo "{{darwin_hosts}}" | tr ' ' '\n' | grep -qx "$target"; then
      just darwin-home-switch "$target"
    elif echo "{{nixos_hosts}}" | tr ' ' '\n' | grep -qx "$target"; then
      just nixos-home-switch "$target"
    else
      echo "Host '$target' is not in a Home Manager lane. Valid: {{valid_hosts}}" >&2
      exit 1
    fi

# Build Home Manager for the current local host, or pass a host explicitly.
home-build host="current":
    #!/usr/bin/env bash
    set -euo pipefail
    target="{{host}}"
    if [ "$target" = "current" ]; then
      target="{{hostname}}"
    fi
    just _validate-hosts "$target"
    if echo "{{darwin_hosts}}" | tr ' ' '\n' | grep -qx "$target"; then
      just darwin-home-build "$target"
    elif echo "{{nixos_hosts}}" | tr ' ' '\n' | grep -qx "$target"; then
      just nixos-home-build "$target"
    else
      echo "Host '$target' is not in a Home Manager lane. Valid: {{valid_hosts}}" >&2
      exit 1
    fi

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

# Cleanup Nix store and old generations
clean:
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    @echo "🧹 Cleaning up Nix store and old generations..."
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    doppler run -- nix-collect-garbage -d
    doppler run -- home-manager expire-generations "-7 days"

# ============================================================================
# Code Quality & Formatting
# ============================================================================

# Format all Nix files
fmt:
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    @echo "✨ Formatting Nix files..."
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    doppler run -- nix fmt -- .

# Run statix linter (warnings only)
lint:
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    @echo "🔍 Running statix linter..."
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    doppler run -- nix develop --command statix check .

# Fix statix issues automatically
lint-fix:
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    @echo "🔧 Fixing statix issues..."
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    doppler run -- nix develop --command statix fix .

# Run deadnix to find unused code
deadnix:
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    @echo "🔍 Checking for unused Nix code..."
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    doppler run -- nix develop --command deadnix .

# Fix deadnix issues automatically (removes unused code)
deadnix-fix:
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    @echo "🔧 Removing unused Nix code..."
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    doppler run -- nix develop --command deadnix --edit .

# ============================================================================
# Pre-commit Hooks
# ============================================================================

# Install pre-commit hooks
install-hooks:
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    @echo "🪝 Installing pre-commit hooks..."
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    doppler run -- nix develop --command pre-commit install

# Run pre-commit on all files
run-hooks:
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    @echo "🪝 Running pre-commit hooks on all files..."
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    doppler run -- nix develop --command pre-commit run --all-files

# Run pre-commit checks
check-pre-commit:
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    @echo "✅ Running pre-commit checks..."
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    doppler run -- nix flake check
