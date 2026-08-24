'use strict';

import Clutter from 'gi://Clutter';
import GLib from 'gi://GLib';
import GObject from 'gi://GObject';
import St from 'gi://St';

const TAU = 2 * Math.PI;

/* Timings and opacities mirror src/Overlay.qml. */
const GROW_MS = 200;
const FADE_IN_MS = 150;
const HOLD_MS = 700;
const FADE_OUT_MS = 800;
const PEAK_OPACITY = Math.round(0.85 * 255);
const START_SCALE = 0.3;

/* The halo reaches 1.3x the ring radius, so the canvas needs 2.6x plus slack. */
const CANVAS_FACTOR = 2.7;

const DEFAULT_RGB = [1, 1, 1];

/**
 * Parse "#rgb", "#rrggbb" or "#rrggbbaa" into normalised [r, g, b].
 * Anything unparseable falls back to white rather than throwing into the
 * compositor's main loop.
 */
export function parseHexColor(hex, fallback = DEFAULT_RGB) {
    if (typeof hex !== 'string')
        return fallback;

    let body = hex.trim().replace(/^#/, '');
    if (body.length === 3)
        body = [...body].map(c => c + c).join('');
    if (body.length === 8)
        body = body.slice(0, 6);
    if (body.length !== 6 || !/^[0-9a-fA-F]{6}$/.test(body))
        return fallback;

    return [0, 2, 4].map(i => parseInt(body.slice(i, i + 2), 16) / 255);
}

/**
 * The highlight ring: a click-through drawing area parented into Main.uiGroup,
 * so it floats above windows without ever entering the input region.
 */
export default class HighlightRing extends St.DrawingArea {
    static {
        GObject.registerClass(this);
    }

    constructor() {
        super({
            reactive: false,
            can_focus: false,
            track_hover: false,
            opacity: 0,
            visible: false,
        });

        this._radius = 60;
        this._rgb = DEFAULT_RGB;
        this._holdId = 0;

        this.set_pivot_point(0.5, 0.5);
        this._resize();
    }

    set radius(value) {
        if (this._radius === value)
            return;
        this._radius = value;
        this._resize();
        this.queue_repaint();
    }

    set color(hex) {
        this._rgb = parseHexColor(hex);
        this.queue_repaint();
    }

    _resize() {
        const size = Math.ceil(2 * this._radius * CANVAS_FACTOR / 2) * 2;
        this.set_size(size, size);
    }

    /** Centre the ring on a pointer position in global coordinates. */
    moveTo(x, y) {
        const [width, height] = this.get_size();
        this.set_position(Math.round(x - width / 2), Math.round(y - height / 2));
    }

    /** Pop the ring at the given pointer position, then fade it out. */
    showAt(x, y) {
        this._cancelHold();
        this.remove_all_transitions();

        this.moveTo(x, y);
        this.set_scale(START_SCALE, START_SCALE);
        this.opacity = 0;
        this.show();

        this.ease({
            duration: GROW_MS,
            mode: Clutter.AnimationMode.EASE_OUT_BACK,
            scale_x: 1,
            scale_y: 1,
        });
        this.ease({
            duration: FADE_IN_MS,
            mode: Clutter.AnimationMode.EASE_OUT_QUAD,
            opacity: PEAK_OPACITY,
        });

        this._holdId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, HOLD_MS, () => {
            this._holdId = 0;
            this._fadeOut();
            return GLib.SOURCE_REMOVE;
        });
    }

    /** Hide immediately, without the fade — used when the cursor goes away. */
    dismiss() {
        if (!this.visible)
            return;
        this._cancelHold();
        this.remove_all_transitions();
        this.opacity = 0;
        this.hide();
    }

    _fadeOut() {
        this.ease({
            duration: FADE_OUT_MS,
            mode: Clutter.AnimationMode.EASE_IN_QUAD,
            opacity: 0,
            onComplete: () => this.hide(),
        });
    }

    _cancelHold() {
        if (this._holdId) {
            GLib.source_remove(this._holdId);
            this._holdId = 0;
        }
    }

    vfunc_repaint() {
        const ctx = this.get_context();
        const [width, height] = this.get_surface_size();
        const cx = width / 2;
        const cy = height / 2;
        const r = this._radius;
        const stroke = Math.max(2, r / 15);
        const [red, green, blue] = this._rgb;

        // Soft dark halo, so the ring reads on light wallpapers too.
        ctx.setLineWidth(r / 6);
        ctx.setSourceRGBA(0, 0, 0, 0.15);
        ctx.arc(cx, cy, 1.3 * r - r / 12, 0, TAU);
        ctx.stroke();

        // Dark contrast rings hugging the outside and inside of the main ring.
        ctx.setLineWidth(stroke);
        ctx.setSourceRGBA(0, 0, 0, 0.6);
        ctx.arc(cx, cy, r + stroke / 2, 0, TAU);
        ctx.stroke();
        ctx.arc(cx, cy, r - 1.5 * stroke, 0, TAU);
        ctx.stroke();

        // The ring itself.
        ctx.setSourceRGBA(red, green, blue, 1);
        ctx.arc(cx, cy, r - stroke / 2, 0, TAU);
        ctx.stroke();

        // Faint inner circle.
        ctx.setLineWidth(2);
        ctx.setSourceRGBA(red, green, blue, 0.25);
        ctx.arc(cx, cy, r / 2 - 1, 0, TAU);
        ctx.stroke();

        ctx.$dispose();
    }

    destroy() {
        this._cancelHold();
        this.remove_all_transitions();
        super.destroy();
    }
}
