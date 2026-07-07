#!/usr/bin/env bash
set -euo pipefail

# Deploy a NixOS host by fetching secrets from 1Password on the deploy machine,
# pushing them to the host, then running nixos-rebuild switch locally on the host.
#
# Usage: ./scripts/deploy-nixos.sh <trinity|morpheus>

HOST="${1:-}"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_macbook_fs}"
SSH_USER="${SSH_USER:-fs}"

OP_VAULT="iac"
TAILSCALE_ITEM="tailscale-key-server-container"
TAILSCALE_FIELD="credential"

case "$HOST" in
  trinity)
    TARGET_IP="10.0.40.61"
    ;;
  morpheus)
    TARGET_IP="10.0.40.19"
    ;;
  *)
    echo "Usage: $0 <trinity|morpheus>" >&2
    exit 1
    ;;
esac

SSH_OPTS=(-i "$SSH_KEY" -o ConnectTimeout=10)
REMOTE="$SSH_USER@$TARGET_IP"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v op >/dev/null 2>&1; then
  echo "1Password CLI (op) not found in PATH" >&2
  exit 1
fi

echo "Fetching Tailscale auth key from 1Password..."
TS_AUTHKEY="$(op read "op://${OP_VAULT}/${TAILSCALE_ITEM}/${TAILSCALE_FIELD}")"

echo "Syncing flake to ${HOST} (${REMOTE})..."
rsync -az --exclude='.git' --exclude='result' -e "ssh ${SSH_OPTS[*]}" \
  "$REPO_ROOT/" "${REMOTE}:/tmp/nix-hosts"

echo "Writing Tailscale auth key on ${HOST}..."
printf '%s' "$TS_AUTHKEY" | ssh "${SSH_OPTS[@]}" "$REMOTE" \
  'sudo mkdir -p /var/lib/tailscale && sudo tee /var/lib/tailscale/tailscale-authkey > /dev/null && sudo chmod 600 /var/lib/tailscale/tailscale-authkey && sudo chown root:root /var/lib/tailscale/tailscale-authkey'

echo "Switching NixOS configuration on ${HOST}..."
ssh "${SSH_OPTS[@]}" "$REMOTE" \
  "cd /tmp/nix-hosts && sudo nixos-rebuild switch --flake .#${HOST}"

echo "Done: ${HOST}"
