# Omarchy Wiggle Finder

A macOS-style **shake-to-find cursor** plugin for [Omarchy](https://omarchy.org/). Rapidly wiggle your mouse to make a glowing ring appear around the cursor — never lose it again on large or multi-monitor setups.

## How It Works

When you shake your mouse back and forth quickly, a highlight ring pops up around the cursor and gracefully fades away after ~1.5 seconds.

The plugin runs as a transparent, input-passthrough overlay — it **never blocks your clicks** or interferes with your workflow.

### Detection Algorithm

- Tracks cursor position at ~60fps via Hyprland IPC
- Counts rapid horizontal direction reversals (left→right→left)
- Triggers when **≥3 reversals** occur within **500ms** with sufficient travel distance
- Filters out jitter and normal mouse movement
- 2-second cooldown between triggers

## Installation

```bash
# Clone the plugin into your Omarchy plugins directory
git clone git@github.com:JiruGutema/omarchy-wiggle.git ~/.config/omarchy/plugins/wiggle-finder

# Validate the plugin
omarchy plugin validate ~/.config/omarchy/plugins/wiggle-finder/

# Enable it
omarchy plugin enable dev.jirehn.wiggle-finder

# Restart the shell
omarchy restart shell
```

## Usage

Just **shake your mouse rapidly** back and forth. A white glowing ring will appear around your cursor and fade out.

That's it. No configuration needed.

## Tuning

If you want to adjust sensitivity, edit `ShakeDetector.js`:

| Constant | Default | Effect |
|---|---|---|
| `WINDOW_MS` | `500` | Time window for counting reversals (ms) |
| `MIN_REVERSALS` | `3` | Direction changes needed to trigger |
| `MIN_DELTA_PX` | `20` | Minimum travel between reversals — filters jitter (px) |
| `COOLDOWN_MS` | `2000` | Cooldown between triggers (ms) |

**More sensitive:** Lower `MIN_REVERSALS` to `2` or `MIN_DELTA_PX` to `15`.  
**Less sensitive:** Raise `MIN_REVERSALS` to `4` or `MIN_DELTA_PX` to `30`.

## Plugin Structure

```
wiggle-finder/
├── manifest.json         # Plugin manifest (overlay type)
├── Overlay.qml           # Transparent fullscreen overlay + highlight animation
└── ShakeDetector.js      # Shake detection algorithm
```

## Requirements

- [Omarchy](https://omarchy.org/) 4.0+ (Quattro)
- Hyprland (ships with Omarchy)

## License

MIT
