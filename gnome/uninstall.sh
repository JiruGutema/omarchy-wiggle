#!/usr/bin/env bash
# Remove Wiggle Finder from GNOME Shell.
set -euo pipefail

UUID="wiggle-finder@jirehn.dev"
DEST="${XDG_DATA_HOME:-$HOME/.local/share}/gnome-shell/extensions/${UUID}"

gnome-extensions disable "$UUID" 2>/dev/null || true
rm -rf "$DEST"
# Drop stored preferences too.
dconf reset -f /org/gnome/shell/extensions/wiggle-finder/ 2>/dev/null || true

echo "Removed ${UUID}."
