#!/usr/bin/env bash
# Build a zip suitable for extensions.gnome.org.
# `gnome-extensions pack` only bundles metadata.json, extension.js, prefs.js and
# schemas/ unless every other module is named explicitly.
set -euo pipefail

UUID="wiggle-finder@jirehn.dev"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${1:-$HERE/dist}"

mkdir -p "$OUT"
gnome-extensions pack --force -o "$OUT" \
  --extra-source=ring.js \
  --extra-source=shakeDetector.js \
  "${HERE}/${UUID}"

echo "Built ${OUT}/${UUID}.shell-extension.zip"
