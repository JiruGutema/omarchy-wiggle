#!/usr/bin/env bash
# Install Wiggle Finder as an Omarchy plugin.
#
# The plugin lives in this subdirectory rather than at the repo root, so
# Omarchy's plugin directory cannot just be a clone of the repo -- it needs
# this folder specifically. That is what this script does.
#
# Usage:
#   ./install.sh          copy the plugin into place
#   ./install.sh --link   symlink instead, so repo edits apply live
set -euo pipefail

PLUGIN_ID="dev.jirehn.wiggle-finder"
PLUGIN_NAME="wiggle-finder"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins/${PLUGIN_NAME}"

MODE="copy"
if [[ "${1:-}" == "--link" ]]; then
  MODE="link"
elif [[ $# -gt 0 ]]; then
  echo "usage: $0 [--link]" >&2
  exit 2
fi

if ! command -v omarchy >/dev/null 2>&1; then
  echo "error: 'omarchy' command not found -- is this an Omarchy system?" >&2
  echo "       For GNOME, use ../gnome/install.sh instead." >&2
  exit 1
fi

if [[ ! -f "${SRC}/manifest.json" ]]; then
  echo "error: no manifest.json in ${SRC}" >&2
  exit 1
fi

mkdir -p "$(dirname "$DEST")"
rm -rf "$DEST"

if [[ "$MODE" == "link" ]]; then
  echo "Linking ${SRC} -> ${DEST}"
  ln -s "$SRC" "$DEST"
else
  echo "Installing ${SRC} -> ${DEST}"
  mkdir -p "$DEST"
  cp -r "${SRC}/manifest.json" "${SRC}/src" "$DEST/"
fi

echo "Validating"
omarchy plugin validate "$DEST"

echo "Enabling"
omarchy plugin enable "$PLUGIN_ID"

echo "Restarting shell"
omarchy restart shell

echo
echo "Installed. To add the settings widget to your bar, put"
echo "  {\"id\": \"${PLUGIN_ID}\"}"
echo "into the bar layout in ~/.config/omarchy/shell.json"
