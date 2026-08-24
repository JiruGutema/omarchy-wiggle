'use strict';

/* Defaults tuned to feel like the Omarchy plugin. */
const DEFAULTS = {
    sensitivity: 3,
    windowMs: 500,
    minDeltaPx: 20,
    cooldownMs: 2000,
};

/* Legs shorter than this carry no reliable direction, so they score nothing. */
const MIN_LEG_PX = 2;

/* One full back-and-forth reverses direction by pi radians. */
const RADIANS_PER_REVERSAL = Math.PI;

const clamp = (value, low, high) => Math.min(high, Math.max(low, value));

const distance = (from, to) => Math.hypot(to.x - from.x, to.y - from.y);

/**
 * Turning angle at `second`, in radians: 0 when the three points are collinear,
 * pi when the pointer doubles straight back on itself.
 */
function turnAngle(first, second, third) {
    const a = distance(first, second);
    const b = distance(second, third);
    if (a < MIN_LEG_PX || b < MIN_LEG_PX)
        return 0;

    const c = distance(first, third);
    // Law of cosines. Clamped, because float error on a collinear triplet can
    // push this just past 1 and make acos return NaN, which would then poison
    // the running total for good.
    const cosine = clamp((a * a + b * b - c * c) / (2 * a * b), -1, 1);
    return Math.PI - Math.acos(cosine);
}

/**
 * Direction-agnostic shake detector.
 *
 * Keeps the pointer track for the last `windowMs` and adds up how much the
 * pointer turned across it. A shake fires when the accumulated turning reaches
 * `sensitivity` reversals' worth AND the pointer hit at least `minDeltaPx`
 * between two consecutive samples. The speed gate is what separates a shake
 * from slow scribbling, which can rack up turning without ever being a shake.
 *
 * Works on any axis: horizontal, vertical and diagonal shakes all trigger.
 *
 * Pure JavaScript on purpose: no GNOME imports, so it can be unit tested
 * standalone (see ../test/shakeDetector.test.js).
 */
export default class ShakeDetector {
    constructor(options = {}) {
        const {sensitivity, windowMs, minDeltaPx, cooldownMs} = {...DEFAULTS, ...options};
        this.sensitivity = sensitivity;
        this.windowMs = windowMs;
        this.minDeltaPx = minDeltaPx;
        this.cooldownMs = cooldownMs;

        this._lastTriggerTime = -Infinity;
        this._samples = [];
    }

    /** Total turning required to fire, in radians. */
    get angleThreshold() {
        return this.sensitivity * RADIANS_PER_REVERSAL;
    }

    /** Drop the current track without touching the cooldown. */
    reset() {
        this._samples = [];
    }

    /**
     * Feed one pointer sample.
     *
     * @param {number} x pointer X in global coordinates
     * @param {number} y pointer Y in global coordinates
     * @param {number} now monotonic timestamp in milliseconds
     * @returns {boolean} true when this sample completes a shake
     */
    addSample(x, y, now) {
        if (now - this._lastTriggerTime < this.cooldownMs) {
            this.reset();
            return false;
        }

        this._samples.push({x, y, t: now});
        this._dropStale(now);

        if (this._samples.length < 3)
            return false;

        const {turning, fastestStep} = this._score();
        if (turning >= this.angleThreshold && fastestStep >= this.minDeltaPx) {
            this.reset();
            this._lastTriggerTime = now;
            return true;
        }

        return false;
    }

    /**
     * Samples arrive in time order, so everything stale sits at the front and
     * one splice clears it. (Removing entries inside a forward loop would skip
     * every other one and quietly widen the window.)
     */
    _dropStale(now) {
        const cutoff = now - this.windowMs;
        let fresh = 0;
        while (fresh < this._samples.length && this._samples[fresh].t < cutoff)
            fresh++;
        if (fresh > 0)
            this._samples.splice(0, fresh);
    }

    _score() {
        const samples = this._samples;
        let turning = 0;
        let fastestStep = 0;

        for (let i = 1; i < samples.length; i++)
            fastestStep = Math.max(fastestStep, distance(samples[i - 1], samples[i]));

        for (let i = 2; i < samples.length; i++)
            turning += turnAngle(samples[i - 2], samples[i - 1], samples[i]);

        return {turning, fastestStep};
    }
}
