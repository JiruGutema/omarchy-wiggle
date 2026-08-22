import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "ShakeDetector.js" as Shake

// Wiggle Finder — Shake the mouse to find your cursor.
// A transparent fullscreen overlay that shows a highlight ring
// when rapid mouse shaking is detected.

Item {
  id: root

  property real cursorX: 0
  property real cursorY: 0
  property bool shakeDetected: false

  // ── Cursor position polling ──────────────────────────────────

  // Uses plain text output "x, y" — one line per call
  Process {
    id: cursorProc
    command: ["hyprctl", "cursorpos"]
    stdout: SplitParser {
      onRead: function(data) {
        var parts = data.split(",")
        if (parts.length === 2) {
          var px = parseInt(parts[0].trim(), 10)
          var py = parseInt(parts[1].trim(), 10)
          if (!isNaN(px) && !isNaN(py)) {
            root.cursorX = px
            root.cursorY = py

            if (Shake.addSample(px, py)) {
              root.triggerHighlight()
            }
          }
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
      if (!cursorProc.running) cursorProc.running = true
    }
  }

  // ── Highlight overlay ────────────────────────────────────────

  function triggerHighlight() {
    shakeDetected = true
    highlightRing.opacity = 0.85
    highlightRing.scale = 0.3
    showAnimation.restart()
    fadeTimer.restart()
  }

  PanelWindow {
    id: overlay
    visible: root.shakeDetected
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    WlrLayershell.namespace: "wiggle-finder"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore

    // Empty mask = entire surface passes input through
    mask: Region {}

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
      root.shakeDetected = false
    }
  }

  // Timer to start the fade-out after the ring is shown
  Timer {
    id: fadeTimer
    interval: 700
    repeat: false
    onTriggered: {
      fadeAnimation.restart()
    }
  }
}
