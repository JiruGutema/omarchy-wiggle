#!/usr/bin/env bash
# Remove Wiggle Finder from Omarchy.
set -euo pipefail

PLUGIN_ID="dev.jirehn.wiggle-finder"
PLUGIN_NAME="wiggle-finder"
DEST="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins/${PLUGIN_NAME}"

if command -v omarchy >/dev/null 2>&1; then
  omarchy plugin disable "$PLUGIN_ID" 2>/dev/null || true
fi

rm -rf "$DEST"

if command -v omarchy >/dev/null 2>&1; then
  omarchy restart shell
fi

echo "Removed ${PLUGIN_ID}."
echo "If you added {\"id\": \"${PLUGIN_ID}\"} to the bar layout in"
echo "~/.config/omarchy/shell.json, remove that entry too."
