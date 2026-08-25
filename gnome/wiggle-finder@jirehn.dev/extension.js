'use strict';

import GLib from 'gi://GLib';
import Meta from 'gi://Meta';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import {getPointerWatcher} from 'resource:///org/gnome/shell/ui/pointerWatcher.js';

import HighlightRing from './ring.js';
import ShakeDetector from './shakeDetector.js';

const POLL_INTERVAL_KEY = 'poll-interval';

/** The cursor tracker moved onto the backend in newer shells. */
function getCursorTracker() {
    if (global.backend?.get_cursor_tracker)
        return global.backend.get_cursor_tracker();
    return Meta.CursorTracker.get_for_display(global.display);
}

export default class WiggleFinderExtension extends Extension {
    enable() {
        this._detector = new ShakeDetector();
        this._ring = new HighlightRing();
        Main.uiGroup.add_child(this._ring);

        this._cursorTracker = getCursorTracker();
        this._pointerWatcher = getPointerWatcher();
        this._watch = null;

        this._settings = this.getSettings();
        this._bindSettings();
    }

    disable() {
        this._removeWatch();
        this._settings.disconnectObject(this);

        this._ring?.destroy();
        this._ring = null;
        this._detector = null;
        this._pointerWatcher = null;
        this._cursorTracker = null;
        this._settings = null;
    }

    /**
     * Apply every setting once, then keep applying it on change. The pointer
     * watch is (re)created here too, since its interval is itself a setting.
     */
    _bindSettings() {
        const handlers = {
            'ring-radius': value => (this._ring.radius = value),
            'ring-color': value => (this._ring.color = value),
            'sensitivity': value => (this._detector.sensitivity = value),
            'shake-window': value => (this._detector.windowMs = value),
            'min-travel': value => (this._detector.minDeltaPx = value),
            'cooldown': value => (this._detector.cooldownMs = value),
            [POLL_INTERVAL_KEY]: value => this._restartWatch(value),
        };

        for (const [key, apply] of Object.entries(handlers)) {
            const read = () => key === 'ring-color'
                ? this._settings.get_string(key)
                : this._settings.get_int(key);

            apply(read());
            this._settings.connectObject(
                `changed::${key}`, () => apply(read()), this);
        }
    }

    _restartWatch(interval) {
        this._removeWatch();
        this._watch = this._pointerWatcher.addWatch(
            interval, (x, y) => this._onPointerMoved(x, y));
    }

    _removeWatch() {
        this._watch?.remove();
        this._watch = null;
    }

    /**
     * Apps that hide the pointer (games, fullscreen video) drop the cursor
     * sprite. Drawing a ring around an invisible cursor there is just noise.
     */
    _isCursorHidden() {
        return !this._cursorTracker?.get_sprite();
    }

    _onPointerMoved(x, y) {
        if (this._isCursorHidden()) {
            this._detector.reset();
            this._ring.dismiss();
            return;
        }

        const now = GLib.get_monotonic_time() / 1000;

        if (this._detector.addSample(x, y, now))
            this._ring.showAt(x, y);
        else if (this._ring.visible)
            this._ring.moveTo(x, y);
    }
}
