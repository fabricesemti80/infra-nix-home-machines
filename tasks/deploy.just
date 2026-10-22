# ============================================================================
# Darwin (macOS System) Management
# ============================================================================

# Ensure output monitoring is available before a build or activation starts.
[private]
_require-nom:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! command -v nom >/dev/null 2>&1; then
      echo "Missing required nom (nix-output-monitor)." >&2
      echo "Try: nix develop --command just quick-update neo" >&2
      exit 127
    fi


# Switch nix-darwin and Home Manager on selected Macs ("all" or comma-list).
darwin-switch host="all":
    #!/usr/bin/env bash
    set -euo pipefail
    just _validate-hosts "{{host}}"
    failed=0
    resolved=$(just _resolve-hosts "{{host}}" "{{enabled_darwin_hosts}}" "{{darwin_hosts}}")
    while IFS= read -r h; do
      [ -z "$h" ] && continue
      if ! just _darwin-switch-one "$h"; then
        just _skip 36 darwin "$h" "switch failed"
        failed=1
      fi
    done <<< "$resolved"
    exit "$failed"

# Switch nix-darwin and Home Manager on a single Mac.
_darwin-switch-one host:
    #!/usr/bin/env bash
    set -euo pipefail
    just _require-nom
    just _check-source
    just _banner 36 darwin "{{host}}" "Switching nix-darwin configuration"
    if command -v brew >/dev/null 2>&1; then
      for trust_target in nikitabobko/tap nikitabobko/tap/aerospace powershell/tap adembc/tap manaflow-ai/cmux; do
        brew trust "$trust_target" 2>/dev/null || true
      done
    fi
    doppler run -- sudo nix run --inputs-from . darwin#darwin-rebuild -- switch --flake .#{{host}} |& nom
    just _darwin-home-switch-one "{{host}}"

# Switch Home Manager on selected Macs ("all" or comma-list).
[private]
darwin-home-switch host="all":
    #!/usr/bin/env bash
    set -euo pipefail
    just _validate-hosts "{{host}}"
    failed=0
    resolved=$(just _resolve-hosts "{{host}}" "{{enabled_darwin_hosts}}" "{{darwin_hosts}}")
    while IFS= read -r h; do
      [ -z "$h" ] && continue
      if ! just _darwin-home-switch-one "$h"; then
        just _skip 34 home "fs@$h" "Home Manager switch failed"
        failed=1
      fi
    done <<< "$resolved"
    exit "$failed"

# Switch Home Manager on a single Mac.
_darwin-home-switch-one host:
    #!/usr/bin/env bash
    set -euo pipefail
    just _require-nom
    just _check-source
    just _banner 34 home "fs@{{host}}" "Switching Home Manager configuration"
    home_name=$(python3 tasks/inventory.py home "{{host}}")
    doppler run -- nix run --inputs-from . home-manager -- switch --flake ".#$home_name" |& nom

# Build nix-darwin and Home Manager on selected Macs ("all" or comma-list).
darwin-build host="all":
    #!/usr/bin/env bash
    set -euo pipefail
    just _validate-hosts "{{host}}"
    failed=0
    resolved=$(just _resolve-hosts "{{host}}" "{{enabled_darwin_hosts}}" "{{darwin_hosts}}")
    while IFS= read -r h; do
      [ -z "$h" ] && continue
      if ! just _darwin-build-one "$h"; then
        just _skip 36 darwin "$h" "build failed"
        failed=1
      fi
    done <<< "$resolved"
    exit "$failed"

# Build nix-darwin and Home Manager on a single Mac.
_darwin-build-one host:
    #!/usr/bin/env bash
    set -euo pipefail
    just _require-nom
    just _check-source
    just _banner 36 darwin "{{host}}" "Building nix-darwin configuration"
    doppler run -- nix run --inputs-from . darwin#darwin-rebuild -- build --flake .#{{host}} |& nom
    just _darwin-home-build-one "{{host}}"

# Build Home Manager on selected Macs ("all" or comma-list).
[private]
darwin-home-build host="all":
    #!/usr/bin/env bash
    set -euo pipefail
    just _validate-hosts "{{host}}"
    failed=0
    resolved=$(just _resolve-hosts "{{host}}" "{{enabled_darwin_hosts}}" "{{darwin_hosts}}")
    while IFS= read -r h; do
      [ -z "$h" ] && continue
      if ! just _darwin-home-build-one "$h"; then
        just _skip 34 home "fs@$h" "Home Manager build failed"
        failed=1
      fi
    done <<< "$resolved"
    exit "$failed"

# Build Home Manager on a single Mac.
_darwin-home-build-one host:
    #!/usr/bin/env bash
    set -euo pipefail
    just _require-nom
    just _check-source
    just _banner 34 home "fs@{{host}}" "Building Home Manager configuration"
    home_name=$(python3 tasks/inventory.py home "{{host}}")
    doppler run -- nix run --inputs-from . home-manager -- build --flake ".#$home_name" |& nom

# Compatibility alias for the old explicit neo command.
[private]
darwin-switch-neo:
    just darwin-switch neo

# Compatibility alias for the old explicit neo home command.
[private]
home-switch-neo:
    just darwin-home-switch neo

# ============================================================================
# Remote NixOS Host Management
# ============================================================================

# Resolve SSH target for a remote NixOS host.
_nixos-target host:
    #!/usr/bin/env bash
    set -euo pipefail
    python3 tasks/inventory.py target "{{host}}"

# Resolve user SSH target for a remote NixOS host.
_nixos-home-target host:
    #!/usr/bin/env bash
    set -euo pipefail
    python3 tasks/inventory.py target "{{host}}"

# Verify a remote NixOS host is reachable before starting a remote build or switch.
_nixos-check-ssh host target:
    #!/usr/bin/env bash
    set -euo pipefail
    if ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new "{{target}}" true 2>&1; then
      exit 0
    fi

    cat >&2 <<'EOF'
    Cannot reach remote NixOS host {{host}} at {{target}} over SSH.

    Check that this machine is on the same LAN/VPN as the server, or that the
    server is already reachable through Tailscale.
    EOF
    exit 1

# Build NixOS on selected remote hosts ("all" or comma-list).
[private]
nixos-build host="all":
    #!/usr/bin/env bash
    set -euo pipefail
    just _validate-hosts "{{host}}"
    failed=0
    resolved=$(just _resolve-hosts "{{host}}" "{{enabled_nixos_hosts}}" "{{nixos_hosts}}")
    while IFS= read -r h; do
      [ -z "$h" ] && continue
      target=$(just _nixos-target "$h")
      if ! ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new "$target" true 2>&1; then
        just _skip 32 nixos "$h" "host is offline (SSH unreachable)"
        failed=1
        continue
      fi
      if ! just _nixos-build-one "$h"; then
        just _skip 32 nixos "$h" "build failed"
        failed=1
      fi
    done <<< "$resolved"
    exit "$failed"

# Build NixOS on a single remote host.
_nixos-build-one host:
    #!/usr/bin/env bash
    set -euo pipefail
    just _require-nom
    just _check-source
    target=$(just _nixos-target "{{host}}")
    just _nixos-check-ssh "{{host}}" "$target"
    just _banner 32 nixos "{{host}}" "Building remote host on ${target}"
    export NIX_SSHOPTS="-o StrictHostKeyChecking=accept-new"
    nix run --inputs-from . nixpkgs#nixos-rebuild -- build --flake .#{{host}} --target-host "$target" --build-host "$target" --no-reexec |& nom
    just _nixos-home-build-one "{{host}}"

# Switch NixOS on selected remote hosts ("all" or comma-list).
[private]
nixos-switch host="all":
    #!/usr/bin/env bash
    set -euo pipefail
    just _validate-hosts "{{host}}"
    failed=0
    resolved=$(just _resolve-hosts "{{host}}" "{{enabled_nixos_hosts}}" "{{nixos_hosts}}")
    while IFS= read -r h; do
      [ -z "$h" ] && continue
      target=$(just _nixos-target "$h")
      if ! ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new "$target" true 2>&1; then
        just _skip 32 nixos "$h" "host is offline (SSH unreachable)"
        failed=1
        continue
      fi
      if ! just _nixos-switch-one "$h"; then
        just _skip 32 nixos "$h" "switch failed"
        failed=1
      fi
    done <<< "$resolved"
    exit "$failed"

# Deploy-time secrets no longer needed (morpheus dropped).
_nixos-push-secrets host target:
    true

# Switch NixOS on a single remote host.
_nixos-switch-one host:
    #!/usr/bin/env bash
    set -euo pipefail
    just _require-nom
    just _check-source
    target=$(just _nixos-target "{{host}}")
    just _nixos-check-ssh "{{host}}" "$target"
    just _banner 32 nixos "{{host}}" "Switching remote host on ${target}"
    just _nixos-push-secrets "{{host}}" "$target"
    export NIX_SSHOPTS="-o StrictHostKeyChecking=accept-new"
    nix run --inputs-from . nixpkgs#nixos-rebuild -- switch --flake .#{{host}} --target-host "$target" --build-host "$target" --sudo --no-reexec --fast |& nom
    just _nixos-home-switch-one "{{host}}"

# Build Home Manager on selected remote NixOS hosts ("all" or comma-list).
[private]
nixos-home-build host="all":
    #!/usr/bin/env bash
    set -euo pipefail
    just _validate-hosts "{{host}}"
    failed=0
    resolved=$(just _resolve-hosts "{{host}}" "{{enabled_nixos_hosts}}" "{{nixos_hosts}}")
    while IFS= read -r h; do
      [ -z "$h" ] && continue
      target=$(just _nixos-target "$h")
      if ! ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new "$target" true 2>&1; then
        just _skip 34 home "fs@$h" "host is offline (SSH unreachable)"
        failed=1
        continue
      fi
      if ! just _nixos-home-build-one "$h"; then
        just _skip 34 home "fs@$h" "Home Manager build failed"
        failed=1
      fi
    done <<< "$resolved"
    exit "$failed"

# Build Home Manager activation package on a single remote host.
_nixos-home-build-one host:
    #!/usr/bin/env bash
    set -euo pipefail
    just _require-nom
    just _check-source
    root_target=$(just _nixos-target "{{host}}")
    just _nixos-check-ssh "{{host}}" "$root_target"
    just _banner 34 home "fs@{{host}}" "Building Home Manager activation package on ${root_target}"
    home_name=$(python3 tasks/inventory.py home "{{host}}")
    flake_path=$(nix flake archive --to "ssh://${root_target}" --json | jq -r .path)
    just _nixos-home-activation-build "$root_target" "$flake_path" "$home_name"

[private]
_nixos-home-activation-build target flake_path home_name:
    #!/usr/bin/env bash
    set -euo pipefail
    just _require-nom
    activation_ref="{{flake_path}}#homeConfigurations.\"{{home_name}}\".activationPackage"
    remote_build="build --extra-experimental-features 'nix-command flakes' --print-out-paths --no-link '$activation_ref'"
    ssh -o StrictHostKeyChecking=accept-new "{{target}}" \
      "if command -v nom >/dev/null 2>&1; then nom $remote_build; elif [ -x \"\$HOME/.nix-profile/bin/nom\" ]; then \"\$HOME/.nix-profile/bin/nom\" $remote_build; else nix $remote_build; fi"


# Switch Home Manager on selected remote NixOS hosts ("all" or comma-list).
[private]
nixos-home-switch host="all":
    #!/usr/bin/env bash
    set -euo pipefail
    just _validate-hosts "{{host}}"
    failed=0
    resolved=$(just _resolve-hosts "{{host}}" "{{enabled_nixos_hosts}}" "{{nixos_hosts}}")
    while IFS= read -r h; do
      [ -z "$h" ] && continue
      root_target=$(just _nixos-target "$h")
      user_target=$(just _nixos-home-target "$h")
      if ! ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new "$root_target" true 2>&1; then
        just _skip 34 home "fs@$h" "host is offline (root SSH unreachable)"
        failed=1
        continue
      fi
      if ! ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new "$user_target" true 2>&1; then
        just _skip 34 home "fs@$h" "host is offline (user SSH unreachable)"
        failed=1
        continue
      fi
      if ! just _nixos-home-switch-one "$h"; then
        just _skip 34 home "fs@$h" "Home Manager switch failed"
        failed=1
      fi
    done <<< "$resolved"
    exit "$failed"

# Switch Home Manager on a single remote host.
_nixos-home-switch-one host:
    #!/usr/bin/env bash
    set -euo pipefail
    just _require-nom
    just _check-source
    root_target=$(just _nixos-target "{{host}}")
    user_target=$(just _nixos-home-target "{{host}}")
    just _nixos-check-ssh "{{host}}" "$root_target"
    just _nixos-check-ssh "{{host}}" "$user_target"
    just _banner 34 home "fs@{{host}}" "Switching Home Manager on ${user_target}"
    home_name=$(python3 tasks/inventory.py home "{{host}}")
    flake_path=$(nix flake archive --to "ssh://${root_target}" --json | jq -r .path)
    out=$(just _nixos-home-activation-build "$root_target" "$flake_path" "$home_name")
    ssh -o StrictHostKeyChecking=accept-new "$user_target" "$out/activate"

# Compatibility alias for switching all enabled remote NixOS hosts.
[private]
nixos-switch-all:
    just nixos-switch

# Compatibility alias for building all enabled remote NixOS hosts.
[private]
nixos-build-all:
    just nixos-build

# Compatibility alias for switching Home Manager on all enabled remote NixOS hosts.
[private]
nixos-home-switch-all:
    just nixos-home-switch

# Compatibility alias for building Home Manager on all enabled remote NixOS hosts.
[private]
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
