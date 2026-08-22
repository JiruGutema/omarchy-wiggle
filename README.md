# Omarchy Wiggle Finder

A macOS-style **shake-to-find cursor** plugin for [Omarchy](https://omarchy.org/). Rapidly wiggle your mouse to make a customizable ring appear around the cursor — never lose it again on large or multi-monitor setups.

## How It Works

When you shake your mouse back and forth quickly, a highlight ring pops up around the cursor and gracefully fades away. 

The plugin runs as a transparent, input-passthrough overlay — it **never blocks your clicks** or interferes with your workflow.

## Installation

```bash
# Clone the plugin into your Omarchy plugins directory
git clone git@github.com:JiruGutema/omarchy-wiggle.git ~/.config/omarchy/plugins/wiggle-finder

# Validate the plugin
omarchy plugin validate ~/.config/omarchy/plugins/wiggle-finder/

# Enable it
omarchy plugin enable dev.jirehn.wiggle-finder

# Add the settings widget to your bar layout (optional)
# Edit ~/.config/omarchy/shell.json and add {"id": "dev.jirehn.wiggle-finder"} to your bar layout

# Restart the shell
omarchy restart shell
```

## Configuration

The plugin includes a convenient top-bar widget (◎) for quick tuning. Click it to adjust:
- **Ring Radius:** Size of the highlight ring.
- **Ring Color:** Click the color preview to open a native color picker.
- **Shake Sensitivity:** Number of direction changes needed to trigger (lower = triggers easier).

All settings take effect instantly.

## Uninstallation / Removal

To completely remove the plugin from your system:

```bash
# 1. Disable the plugin
omarchy plugin disable dev.jirehn.wiggle-finder

# 2. Remove the plugin files
rm -rf ~/.config/omarchy/plugins/wiggle-finder/

# 3. Restart the shell
omarchy restart shell
```

*Note: If you manually added the settings widget to your `~/.config/omarchy/shell.json` bar layout, you should also remove the `{"id": "dev.jirehn.wiggle-finder"}` entry from your config file.*

## Plugin Structure

```
wiggle-finder/
├── manifest.json         # Plugin manifest (overlay & bar-widget)
└── src/
    ├── Overlay.qml       # Transparent fullscreen overlay + highlight animation
    ├── BarWidget.qml     # Top-bar settings widget UI
    └── ShakeDetector.js  # Shake detection algorithm
```

## Requirements

- [Omarchy](https://omarchy.org/) 4.0+ (Quattro)
- Hyprland (ships with Omarchy)

## License

MIT
