import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import "ShakeDetector.js" as Shake

// Wiggle Finder — Shake the mouse to find your cursor.
// A transparent fullscreen overlay that shows a highlight ring
// when rapid mouse shaking is detected.

PanelWindow {
    id: root

    // Cover the entire screen on the overlay layer
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // Transparent background — we only render the highlight ring
    color: "transparent"

    // Place on the overlay layer so it's above everything
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.namespace: "wiggle-finder"

    // Empty mask = entire surface passes input through
    mask: Region {}

    // Current cursor position
    property real cursorX: 0
    property real cursorY: 0
    property bool shakeDetected: false

    // ── Cursor position polling ──────────────────────────────────

    // Process to query Hyprland for cursor position
    Process {
        id: cursorProc
        command: ["hyprctl", "cursorpos", "-j"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    var pos = JSON.parse(data);
                    root.cursorX = pos.x;
                    root.cursorY = pos.y;

                    // Feed position to shake detector
                    if (Shake.addSample(pos.x, pos.y)) {
                        root.triggerHighlight();
                    }
                } catch (e) {
                    // Ignore parse errors (partial output, etc.)
                }
            }
        }
    }

    // Poll cursor position at ~60fps
    Timer {
        id: pollTimer
        interval: 16
        running: true
        repeat: true
        onTriggered: {
            cursorProc.running = true;
        }
    }

    // ── Highlight ring ───────────────────────────────────────────

    function triggerHighlight() {
        shakeDetected = true;
        highlightRing.opacity = 0.85;
        highlightRing.scale = 0.3;
        showAnimation.restart();
        fadeTimer.restart();
    }

    // The animated highlight ring
    Rectangle {
        id: highlightRing
        width: 120
        height: 120
        radius: 60
        color: "transparent"
        border.color: Qt.rgba(1, 1, 1, 0.9)
        border.width: 3
        opacity: 0
        scale: 0.3
        visible: opacity > 0

        // Position centered on cursor
        x: root.cursorX - width / 2
        y: root.cursorY - height / 2

        // Inner glow ring
        Rectangle {
            anchors.centerIn: parent
            width: 80
            height: 80
            radius: 40
            color: "transparent"
            border.color: Qt.rgba(1, 1, 1, 0.4)
            border.width: 2
        }

        // Outer soft glow
        Rectangle {
            anchors.centerIn: parent
            width: 140
            height: 140
            radius: 70
            color: "transparent"
            border.color: Qt.rgba(1, 1, 1, 0.15)
            border.width: 8
        }
    }

    // Scale-up + fade-in animation
    ParallelAnimation {
        id: showAnimation

        NumberAnimation {
            target: highlightRing
            property: "scale"
            from: 0.3
            to: 1.0
            duration: 200
            easing.type: Easing.OutBack
        }

        NumberAnimation {
            target: highlightRing
            property: "opacity"
            from: 0.0
            to: 0.85
            duration: 150
            easing.type: Easing.OutQuad
        }
    }

    // Fade-out animation
    NumberAnimation {
        id: fadeAnimation
        target: highlightRing
        property: "opacity"
        from: 0.85
        to: 0.0
        duration: 800
        easing.type: Easing.InQuad
        onFinished: {
            root.shakeDetected = false;
        }
    }

    // Timer to start the fade-out after the ring is shown
    Timer {
        id: fadeTimer
        interval: 700  // Ring stays visible for 700ms, then fades for 800ms
        repeat: false
        onTriggered: {
            fadeAnimation.restart();
        }
    }
}
