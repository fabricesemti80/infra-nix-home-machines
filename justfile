import "tasks/deploy.just"
import "tasks/maintenance.just"
import "tasks/quality.just"

# Justfile for Nix Darwin and Home Manager system management

# Determine the hostname dynamically
hostname := `hostname`
enabled_darwin_hosts := `python3 tasks/inventory.py hosts darwin --enabled`
enabled_nixos_hosts := `python3 tasks/inventory.py hosts nixos --enabled`

# All known host names in the flake (used to validate explicit host filters).
valid_hosts := `python3 tasks/inventory.py hosts`

# Per-lane host sets: every host that can be deployed in a given lane.
darwin_hosts := `python3 tasks/inventory.py hosts darwin`
nixos_hosts := `python3 tasks/inventory.py hosts nixos`

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

# Refuse unknown source files without changing the user's Git index.
_check-source:
    python3 tasks/check-source.py

# ============================================================================
# Quick Update Commands
# ============================================================================

# Host filters limit deployments, not shared input updates or cleanup.
# Prune old generations, update inputs, build selected lanes, then switch.
quick-update hosts="all":
    #!/usr/bin/env bash
    set -euo pipefail
    just _validate-hosts "{{hosts}}"
    just _check-source
    just clean
    just update

    # Build a per-lane filter (silently dropping cross-lane entries) and call each lane
    # that has at least one host to process.
    darwin_filter=$(just _quick-update-filter "{{hosts}}" "{{enabled_darwin_hosts}}" "{{darwin_hosts}}")
    nixos_filter=$(just _quick-update-filter "{{hosts}}" "{{enabled_nixos_hosts}}" "{{nixos_hosts}}")

    failed=0
    if [ -n "$darwin_filter" ]; then
      if just darwin-build "$darwin_filter"; then
        just darwin-switch "$darwin_filter" || failed=1
      else
        echo "Darwin build failed; skipping switch for $darwin_filter" >&2
        failed=1
      fi
    fi
    if [ -n "$nixos_filter" ]; then
      if just nixos-build "$nixos_filter"; then
        just nixos-switch "$nixos_filter" || failed=1
      else
        echo "NixOS build failed; skipping switch for $nixos_filter" >&2
        failed=1
      fi
    fi
    exit "$failed"

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
    nix flake check

# Open nix repl with current flake
[private]
repl:
    @just _banner 33 flake repl "Opening Nix REPL"
    nix repl .#


# Evaluate native hosts and homes without activating anything.
check:
    python3 tasks/check-configs.py
    nix flake check
    python3 -m unittest discover -s tests

# List declared machines and deployment targets.
hosts:
    python3 tasks/inventory.py show
