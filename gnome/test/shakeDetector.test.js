#!/usr/bin/env gjs -m
'use strict';

// Run with:  gjs -m gnome/test/shakeDetector.test.js
import System from 'system';

import ShakeDetector from '../wiggle-finder@jirehn.dev/shakeDetector.js';

let failures = 0;

function check(name, condition) {
    if (condition) {
        print(`  ok   ${name}`);
    } else {
        print(`  FAIL ${name}`);
        failures++;
    }
}

const CENTRE = {x: 960, y: 540};

/**
 * Drive a smooth sinusoidal shake, the way a hand actually moves, and report
 * whether the detector ever fired. Coordinates are rounded because that is
 * what the pointer watcher hands over.
 */
function shake(detector, options = {}) {
    const {
        axis = 'x',
        amplitude = 150,
        freq = 5,
        durationMs = 1000,
        stepMs = 16,
        startMs = 10000,
    } = options;

    let now = startMs;
    let fired = false;

    for (let elapsed = 0; elapsed < durationMs; elapsed += stepMs) {
        const offset = Math.round(amplitude * Math.sin(2 * Math.PI * freq * (elapsed / 1000)));
        const x = axis === 'y' ? CENTRE.x : CENTRE.x + offset;
        const y = axis === 'x' ? CENTRE.y : CENTRE.y + offset;
        if (detector.addSample(x, y, now))
            fired = true;
        now += stepMs;
    }
    return fired;
}

/** A straight drag across the screen at constant speed. */
function drag(detector, {distancePx = 1500, stepMs = 16, pxPerStep = 30, startMs = 10000} = {}) {
    let now = startMs;
    let fired = false;
    for (let travelled = 0; travelled < distancePx; travelled += pxPerStep) {
        if (detector.addSample(CENTRE.x + travelled, CENTRE.y, now))
            fired = true;
        now += stepMs;
    }
    return fired;
}

print('ShakeDetector');

// --- Direction independence: the whole point of the 2D rewrite --------------
check('a horizontal shake triggers',
    shake(new ShakeDetector(), {axis: 'x'}));

check('a vertical shake triggers',
    shake(new ShakeDetector(), {axis: 'y'}));

check('a diagonal shake triggers',
    shake(new ShakeDetector(), {axis: 'xy'}));

// --- Things that must NOT trigger -------------------------------------------
check('a straight drag across the screen does not trigger',
    !drag(new ShakeDetector()));

check('small jitter does not trigger',
    !shake(new ShakeDetector(), {amplitude: 5}));

check('slow wide scribbling does not trigger (speed gate)',
    !shake(new ShakeDetector(), {amplitude: 300, freq: 0.5, durationMs: 4000}));

check('a single sweep out and back does not trigger',
    !shake(new ShakeDetector(), {freq: 1, durationMs: 500}));

// --- Tuning knobs ------------------------------------------------------------
check('a higher sensitivity demands a harder shake',
    !shake(new ShakeDetector({sensitivity: 8}), {amplitude: 150, freq: 5}));

check('a lower sensitivity triggers more easily',
    shake(new ShakeDetector({sensitivity: 2}), {amplitude: 120, freq: 4}));

check('a larger min-travel demands a faster shake',
    !shake(new ShakeDetector({minDeltaPx: 90}), {amplitude: 150, freq: 5}));

check('shaking spread beyond the window does not accumulate',
    !shake(new ShakeDetector({windowMs: 200}), {amplitude: 150, freq: 1.5, durationMs: 3000}));

// --- Cooldown ----------------------------------------------------------------
{
    const detector = new ShakeDetector();
    check('first shake fires', shake(detector, {startMs: 10000}));
    check('a second shake inside the cooldown is suppressed',
        !shake(detector, {startMs: 11200, durationMs: 600}));
    check('a second shake after the cooldown fires again',
        shake(detector, {startMs: 20000}));
}

// --- Robustness --------------------------------------------------------------
check('collinear samples never poison the angle total with NaN',
    !drag(new ShakeDetector(), {pxPerStep: 200, distancePx: 8000}));

if (failures > 0) {
    print(`\n${failures} test(s) failed`);
    System.exit(1);
}
print('\nall tests passed');
