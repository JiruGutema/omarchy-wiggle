#!/usr/bin/env bash
# Install Wiggle Finder as a GNOME Shell extension.
set -euo pipefail

UUID="wiggle-finder@jirehn.dev"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/${UUID}"
DEST="${XDG_DATA_HOME:-$HOME/.local/share}/gnome-shell/extensions/${UUID}"

if [[ ! -d "$SRC" ]]; then
  echo "error: cannot find ${SRC}" >&2
  exit 1
fi

echo "Installing ${UUID} -> ${DEST}"
rm -rf "$DEST"
mkdir -p "$DEST"
cp -r "$SRC/." "$DEST/"

echo "Compiling GSettings schema"
glib-compile-schemas "${DEST}/schemas"

echo
echo "Installed. Next:"
if [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]]; then
  echo "  1. Log out and back in (Wayland cannot reload the shell in place)."
  echo "  2. gnome-extensions enable ${UUID}"
else
  echo "  1. Restart the shell: Alt+F2, type 'r', press Enter."
  echo "  2. gnome-extensions enable ${UUID}"
fi
echo "  3. Settings:  gnome-extensions prefs ${UUID}"
