#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Aerospace Toggle
# @raycast.mode compact

# Optional parameters:
# @raycast.icon raycast-aerospace-toggle.png
# @raycast.packageName Window Management

# Documentation:
# @raycast.description Toggle AeroSpace window management on or off.

set -euo pipefail

aerospace_bin="/opt/homebrew/bin/aerospace"
aerospace_app="/Applications/AeroSpace.app"

if ! "$aerospace_bin" --version 2>/dev/null | grep -q "server version: [0-9]"; then
  open "$aerospace_app"

  for _ in {1..20}; do
    if "$aerospace_bin" --version 2>/dev/null | grep -q "server version: [0-9]"; then
      break
    fi
    sleep 0.5
  done
fi

"$aerospace_bin" --version 2>/dev/null | grep -q "server version: [0-9]" || {
  echo "AeroSpace server is not running"
  exit 1
}

if "$aerospace_bin" enable on --fail-if-noop >/dev/null 2>&1; then
  "$aerospace_bin" reload-config >/dev/null 2>&1
  "$aerospace_bin" run-callback --for-every-window on-window-detected >/dev/null 2>&1 || true
  echo "AeroSpace enabled"
else
  "$aerospace_bin" enable off
  echo "AeroSpace disabled"
fi
