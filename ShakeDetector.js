// ShakeDetector.js — Direction-reversal shake detection algorithm

.pragma library

// State
var _samples = [];
var _lastDx = 0;
var _lastX = -1;
var _lastReversalX = -1;
var _reversals = [];
var _lastTriggerTime = 0;
var _initialized = false;

// Shared Configuration
var config = {
    ringRadius: 60,
    ringColor: "#ffffff",
    sensitivity: 3,
    WINDOW_MS: 500,
    MIN_DELTA_PX: 20,
    COOLDOWN_MS: 2000
};

var _listeners = [];

function addListener(cb) {
    _listeners.push(cb);
}

function updateConfig(radius, color, sensitivity) {
    config.ringRadius = radius;
    config.ringColor = color;
    config.sensitivity = sensitivity;
    for (var i = 0; i < _listeners.length; i++) {
        _listeners[i]();
    }
}

function reset() {
    _samples = [];
    _lastDx = 0;
    _lastX = -1;
    _lastReversalX = -1;
    _reversals = [];
    _initialized = false;
}

// Feed a new cursor position sample
function addSample(x, y) {
    var now = Date.now();

    if (now - _lastTriggerTime < config.COOLDOWN_MS) return false;

    if (!_initialized) {
        _lastX = x;
        _lastReversalX = x;
        _initialized = true;
        return false;
    }

    var dx = x - _lastX;
    if (Math.abs(dx) < 2) return false;

    var direction = dx > 0 ? 1 : -1;

    if (_lastDx !== 0 && direction !== _lastDx) {
        var travel = Math.abs(x - _lastReversalX);
        if (travel >= config.MIN_DELTA_PX) {
            _reversals.push(now);
            _lastReversalX = x;
        }
    }

    _lastDx = direction;
    _lastX = x;

    var cutoff = now - config.WINDOW_MS;
    while (_reversals.length > 0 && _reversals[0] < cutoff) {
        _reversals.shift();
    }

    if (_reversals.length >= config.sensitivity) {
        _lastTriggerTime = now;
        _reversals = [];
        reset();
        _lastTriggerTime = now;
        return true;
    }

    return false;
}
