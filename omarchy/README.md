# Wiggle Finder for Omarchy

A macOS-style **shake-to-find cursor** plugin for [Omarchy](https://omarchy.org/).
Rapidly wiggle your mouse and a customizable ring appears around the cursor,
then fades away.

The plugin runs as a transparent, input-passthrough overlay — it **never blocks
your clicks** or interferes with your workflow.

## Requirements

- [Omarchy](https://omarchy.org/) 4.0+ (Quattro)
- Hyprland (ships with Omarchy)

## Install

The plugin lives in this subdirectory, not at the repo root, so Omarchy's plugin
directory cannot simply be a clone of this repo — it needs *this folder*.

```bash
git clone git@github.com:JiruGutema/wiggle-finder.git
cd wiggle-finder
./omarchy/install.sh
```

That copies the plugin into `~/.config/omarchy/plugins/wiggle-finder`, validates
it, enables it, and restarts the shell. Use `./omarchy/install.sh --link` to
symlink instead, so edits in the repo apply without reinstalling.

Doing it by hand instead:

```bash
cp -r omarchy ~/.config/omarchy/plugins/wiggle-finder
omarchy plugin validate ~/.config/omarchy/plugins/wiggle-finder/
omarchy plugin enable dev.jirehn.wiggle-finder
omarchy restart shell
```

To add the settings widget to your bar, put `{"id": "dev.jirehn.wiggle-finder"}`
into the bar layout in `~/.config/omarchy/shell.json`.

## Configure

The plugin includes a top-bar widget (◎). Click it to adjust:

| Setting | What it does |
|---|---|
| Ring radius | Size of the highlight ring |
| Ring color | Click the swatch for a native color picker |
| Shake sensitivity | Direction changes needed to trigger; lower triggers more easily |

All settings take effect instantly. They are held in memory and reset when the
shell restarts.

## Remove

```bash
./omarchy/uninstall.sh
```

## Structure

```
omarchy/
├── manifest.json         # Plugin manifest (overlay & bar-widget)
├── src/
│   ├── Overlay.qml       # Transparent fullscreen overlay + highlight animation
│   ├── BarWidget.qml     # Top-bar settings widget UI
│   └── ShakeDetector.js  # Shake detection algorithm
├── install.sh
└── uninstall.sh
```

## Known limitation

`ShakeDetector.js` only inspects the **X axis** — it receives `(x, y)` and never
reads `y`, so a purely vertical shake never triggers it. The GNOME port in
[`../gnome/`](../gnome/) replaced this with direction-agnostic detection based
on accumulated turning angle. That algorithm is plain JavaScript with no GNOME
dependencies, so porting it back here would be straightforward.
