// ShakeDetector.js — Direction-reversal shake detection algorithm
// Detects rapid horizontal back-and-forth mouse movement (wiggle/shake)

.pragma library

// Configuration
var WINDOW_MS = 500;        // Time window to look for reversals (ms)
var MIN_REVERSALS = 3;      // Minimum direction reversals to trigger
var MIN_DELTA_PX = 20;      // Minimum movement (px) between reversals to filter jitter
var COOLDOWN_MS = 2000;     // Cooldown after a shake is detected (ms)

// State
var _samples = [];          // Array of { x, y, t }
var _lastDx = 0;            // Last horizontal delta direction (+1 or -1)
var _lastX = -1;
var _lastReversalX = -1;    // X position at last reversal
var _reversals = [];        // Array of timestamps when reversals occurred
var _lastTriggerTime = 0;   // Timestamp of last shake trigger
var _initialized = false;

function reset() {
    _samples = [];
    _lastDx = 0;
    _lastX = -1;
    _lastReversalX = -1;
    _reversals = [];
    _initialized = false;
}

// Feed a new cursor position sample.
// Returns true if a shake was detected.
function addSample(x, y) {
    var now = Date.now();

    // Cooldown check
    if (now - _lastTriggerTime < COOLDOWN_MS) {
        return false;
    }

    // Initialize on first sample
    if (!_initialized) {
        _lastX = x;
        _lastReversalX = x;
        _initialized = true;
        return false;
    }

    var dx = x - _lastX;

    // Ignore tiny movements (noise)
    if (Math.abs(dx) < 2) {
        return false;
    }

    var direction = dx > 0 ? 1 : -1;

    // Check for direction reversal
    if (_lastDx !== 0 && direction !== _lastDx) {
        // Only count if we've moved far enough since the last reversal
        var travel = Math.abs(x - _lastReversalX);
        if (travel >= MIN_DELTA_PX) {
            _reversals.push(now);
            _lastReversalX = x;
        }
    }

    _lastDx = direction;
    _lastX = x;

    // Prune old reversals outside the time window
    var cutoff = now - WINDOW_MS;
    while (_reversals.length > 0 && _reversals[0] < cutoff) {
        _reversals.shift();
    }

    // Check if we have enough reversals to trigger
    if (_reversals.length >= MIN_REVERSALS) {
        _lastTriggerTime = now;
        _reversals = [];
        reset();
        _lastTriggerTime = now; // re-set after reset clears nothing about trigger time
        return true;
    }

    return false;
}
