# Wiggle Finder

A macOS-style **shake-to-find cursor**. Rapidly wiggle your mouse and a
customizable ring appears around the cursor, then fades away — never lose it
again on large or multi-monitor setups.

The overlay is transparent and input-passthrough. It **never blocks your
clicks** or interferes with your workflow.

Two implementations live here, one per desktop. They share a design, not a
codebase.

| Desktop | Folder | Status |
|---------|--------|--------|
| [Omarchy](https://omarchy.org/) 4.0+ (Hyprland) | [`omarchy/`](omarchy/) | Original implementation — Quickshell / QML |
| GNOME Shell 45–48 | [`gnome/`](gnome/) | Full port — GJS extension, verified on GNOME 46 |

## Install

**Omarchy** — see [omarchy/README.md](omarchy/README.md):

```bash
git clone git@github.com:JiruGutema/wiggle-finder.git
cd omarchy-wiggle
./omarchy/install.sh
```

**GNOME** — see [gnome/README.md](gnome/README.md):

```bash
git clone git@github.com:JiruGutema/wiggle-finder.git
cd omarchy-wiggle
./gnome/install.sh
# then log out and back in, and:
gnome-extensions enable wiggle-finder@jirehn.dev
```

> The Omarchy plugin lives in `omarchy/` rather than at the repo root, so the
> Omarchy plugins directory cannot just be a clone of this repo. `install.sh`
> puts the right folder in the right place.

## Configure

Both versions expose ring radius, ring color and shake sensitivity, applied
instantly.

- **Omarchy:** a top-bar widget (◎). Settings are held in memory.
- **GNOME:** `gnome-extensions prefs wiggle-finder@jirehn.dev`. Settings persist
  in GSettings, and the detection timings are exposed too.

## The two differ in one way that matters

The Omarchy `ShakeDetector.js` inspects the **X axis only** — it takes `(x, y)`
and never reads `y`, so a purely vertical shake never triggers it.

The GNOME version replaced this with direction-agnostic detection that
accumulates turning angle over the recent pointer track, so horizontal, vertical
and diagonal shakes all work. That algorithm is plain JavaScript with no GNOME
dependencies, so porting it back to Omarchy would be straightforward.

## Structure

```
omarchy/          Omarchy plugin (Quickshell/QML, Hyprland)
gnome/            GNOME Shell extension (GJS)
```

## License

MIT
