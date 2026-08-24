'use strict';

import Adw from 'gi://Adw';
import Gdk from 'gi://Gdk';
import Gio from 'gi://Gio';
import Gtk from 'gi://Gtk';
import {ExtensionPreferences} from 'resource:///org/gnome/Shell/Extensions/js/extensions/prefs.js';

const clamp01 = value => Math.min(1, Math.max(0, value));
const toHexByte = value => Math.round(clamp01(value) * 255).toString(16).padStart(2, '0');
const rgbaToHex = rgba => `#${toHexByte(rgba.red)}${toHexByte(rgba.green)}${toHexByte(rgba.blue)}`;

/** A spin row bound two-way to an integer key. */
function spinRow(settings, key, title, subtitle, lower, upper, step) {
    const row = new Adw.SpinRow({
        title,
        subtitle,
        numeric: true,
        adjustment: new Gtk.Adjustment({
            lower,
            upper,
            'step-increment': step,
            'page-increment': step * 5,
        }),
    });
    settings.bind(key, row, 'value', Gio.SettingsBindFlags.DEFAULT);
    return row;
}

/** A color row backed by a hex string key. */
function colorRow(settings, key, title, subtitle) {
    const button = new Gtk.ColorDialogButton({
        dialog: new Gtk.ColorDialog({'with-alpha': false}),
        valign: Gtk.Align.CENTER,
    });

    const load = () => {
        const rgba = new Gdk.RGBA();
        if (rgba.parse(settings.get_string(key)))
            button.set_rgba(rgba);
    };
    load();

    button.connect('notify::rgba', () => {
        const hex = rgbaToHex(button.get_rgba());
        if (hex !== settings.get_string(key))
            settings.set_string(key, hex);
    });
    const changedId = settings.connect(`changed::${key}`, load);
    button.connect('destroy', () => settings.disconnect(changedId));

    const row = new Adw.ActionRow({title, subtitle});
    row.add_suffix(button);
    row.activatable_widget = button;
    return row;
}

export default class WiggleFinderPreferences extends ExtensionPreferences {
    fillPreferencesWindow(window) {
        const settings = this.getSettings();

        const page = new Adw.PreferencesPage({
            title: 'Wiggle Finder',
            icon_name: 'input-mouse-symbolic',
        });

        const appearance = new Adw.PreferencesGroup({
            title: 'Appearance',
            description: 'How the highlight ring looks when it appears.',
        });
        appearance.add(spinRow(settings, 'ring-radius', 'Ring radius',
            'Size of the highlight ring, in pixels.', 20, 150, 5));
        appearance.add(colorRow(settings, 'ring-color', 'Ring color',
            'Color of the highlight ring.'));
        page.add(appearance);

        const detection = new Adw.PreferencesGroup({
            title: 'Detection',
            description: 'How hard you have to shake before the ring appears.',
        });
        detection.add(spinRow(settings, 'sensitivity', 'Shake sensitivity',
            'How many back-and-forth reversals the shake must add up to. Lower triggers more easily.', 2, 8, 1));
        detection.add(spinRow(settings, 'min-travel', 'Minimum speed',
            'Pixels the pointer must cover between two samples. Raise this if the ring appears too readily.', 5, 100, 5));
        page.add(detection);

        const timing = new Adw.PreferencesGroup({
            title: 'Timing',
            description: 'Fine tuning. The defaults suit most people.',
        });
        timing.add(spinRow(settings, 'shake-window', 'Shake window',
            'How much of the recent pointer track counts toward a shake, in milliseconds.', 200, 1500, 50));
        timing.add(spinRow(settings, 'cooldown', 'Cooldown',
            'Quiet period after a trigger before another shake can fire, in milliseconds.', 0, 5000, 100));
        timing.add(spinRow(settings, 'poll-interval', 'Pointer poll interval',
            'How often the pointer position is sampled, in milliseconds.', 8, 100, 1));
        page.add(timing);

        window.add(page);
    }
}
