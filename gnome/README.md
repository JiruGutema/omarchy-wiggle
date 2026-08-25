# Wiggle Finder for GNOME Shell

A GNOME Shell port of the Omarchy Wiggle Finder plugin: shake the mouse and a
highlight ring pops up around the cursor, then fades away.

Same behaviour, same look, same tuning knobs — but rewritten for GNOME Shell's
extension system, because Omarchy's plugin API (Quickshell + QML + Hyprland)
does not exist here.

## What changed from the Omarchy plugin

| | Omarchy plugin | GNOME extension |
|---|---|---|
| Language | QML + JS | GJS (ES modules) |
| Cursor position | `hyprctl cursorpos` subprocess, polled | `pointerWatcher`, in-process |
| Overlay | `PanelWindow` on `wlr-layer-shell` | `St.DrawingArea` in `Main.uiGroup` |
| Click-through | `mask: Region {}` | non-reactive actor, never in the input region |
| Ring drawing | nested QML `Rectangle`s | Cairo arcs in `vfunc_repaint` |
| Settings UI | top-bar widget (`◎`) | Adwaita preferences window |
| Settings storage | in-memory | GSettings (persists across restarts) |
| Shake detection | X axis only | any direction |

Four things genuinely improve on the way over:

- **No subprocess per frame.** The Omarchy overlay spawns `hyprctl cursorpos`
  every 16 ms. GNOME hands the pointer position over in-process, so the same
  sampling rate costs approximately nothing.
- **Settings persist.** GSettings keeps them across shell restarts, and the
  timing constants that were hardcoded in `ShakeDetector.js` are exposed too.
- **Shakes work in any direction.** See below.
- **It stays out of the way when the cursor is hidden.** Games and fullscreen
  video drop the cursor sprite; the ring stays down while that is the case.

## Deliberate differences from the Omarchy plugin

The GNOME version does **not** detect shakes the same way, on purpose.

The Omarchy `ShakeDetector.js` counts direction reversals on the **X axis only**
— it takes `(x, y)` but never reads `y`. A purely vertical shake never triggers
it. The GNOME version instead accumulates *turning angle* over the recent
pointer track, so horizontal, vertical and diagonal shakes all work.

Two settings therefore mean something slightly different here:

- **Shake sensitivity** is how many reversals' worth of *turning* must add up
  (each full reversal is pi radians), rather than a raw count of reversals.
- **Minimum speed** (was "minimum travel") gates on distance between two
  consecutive samples, not between reversals. It is what stops slow scribbling
  from registering as a shake.

A straight drag across the screen never triggers either version.

If you want the Omarchy behaviour back, `git log` has the original port — the
first version of `shakeDetector.js` is a line-for-line translation of
`../omarchy/src/ShakeDetector.js`.

## Requirements

- GNOME Shell 45–50. Developed and verified against 46; 47–50 were audited
  against upstream API changes rather than run.
- Wayland. X11 also works on GNOME 45–49 — [GNOME 50 removed the X11
  session](https://release.gnome.org/50/) entirely.

## Install

```bash
./install.sh
```

Then, because Wayland cannot reload the shell in place, log out and back in,
and enable it. (On an X11 session — GNOME 49 and earlier — you can reload the
shell instead: <kbd>Alt</kbd>+<kbd>F2</kbd>, `r`, <kbd>Enter</kbd>.)

```bash
gnome-extensions enable wiggle-finder@jirehn.dev
```

## Configure

```bash
gnome-extensions prefs wiggle-finder@jirehn.dev
```

or find **Wiggle Finder** in the Extensions app.

| Setting | Default | What it does |
|---|---|---|
| Ring radius | 60 px | Size of the highlight ring |
| Ring color | `#ffffff` | Ring color, via a native color picker |
| Shake sensitivity | 3 | Reversals' worth of turning needed; lower triggers more easily |
| Minimum speed | 20 px | Pixels between consecutive samples; raise it if the ring appears too readily |
| Shake window | 500 ms | How much of the recent pointer track counts |
| Cooldown | 2000 ms | Quiet period after a trigger |
| Pointer poll interval | 16 ms | How often the pointer is sampled |

Changes apply instantly — no restart.

## Remove

```bash
./uninstall.sh
```

## Develop

```bash
gjs -m test/shakeDetector.test.js           # unit tests for the detection algorithm
./pack.sh                                   # build a zip for extensions.gnome.org
journalctl --user -f -o cat /usr/bin/gnome-shell   # watch for runtime errors
```

Lint the bundle against the extensions.gnome.org review rules before publishing:

```bash
python3 -m venv venv && . venv/bin/activate && pip install -U shexli
./pack.sh && shexli dist/wiggle-finder@jirehn.dev.shell-extension.zip
```

## Layout

```
gnome/
├── wiggle-finder@jirehn.dev/
│   ├── metadata.json        # Extension manifest
│   ├── extension.js         # Lifecycle, settings binding, pointer watch
│   ├── ring.js              # Cairo-drawn highlight ring + animation
│   ├── shakeDetector.js     # Direction-agnostic shake detection (unit tested)
│   ├── prefs.js             # Adwaita preferences window
│   └── schemas/             # GSettings schema
├── test/
│   └── shakeDetector.test.js
├── install.sh
├── uninstall.sh
└── pack.sh
```

## Prior art

[`wiggle@mechtifs`](https://github.com/mechtifs/wiggle) is an existing GNOME
extension in this space. It *magnifies the cursor sprite* on shake; this one
draws the macOS-style ring around it instead. If you only want a bigger cursor,
use that one.

Its angle-accumulation approach is what convinced us to drop the X-axis-only
detector, and its cursor-sprite check is where the hidden-cursor guard came
from. No code was copied. Running both at once means both effects fire on the
same shake.
