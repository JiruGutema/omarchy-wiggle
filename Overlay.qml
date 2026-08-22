import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.Commons
import "ShakeDetector.js" as Shake

// Wiggle Finder — Shake the mouse to find your cursor.
// A transparent fullscreen overlay that shows a highlight ring
// when rapid mouse shaking is detected.

Item {
  id: root

  property real cursorX: 0
  property real cursorY: 0

  property int ringRadius: 60
  property string ringColor: "#ffffff"

  Component.onCompleted: {
    ringRadius = Shake.config.ringRadius;
    ringColor = Shake.config.ringColor;
    
    Shake.addListener(function() {
      root.ringRadius = Shake.config.ringRadius;
      root.ringColor = Shake.config.ringColor;
    });
  }

  // ── Cursor position polling ──────────────────────────────────

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
    highlightRing.opacity = 0.85
    highlightRing.scale = 0.3
    showAnimation.restart()
    fadeTimer.restart()
  }

  // Keep the PanelWindow always visible so Wayland doesn't have to map/unmap it,
  // which can drop frames or fail to show. It's completely transparent and passes input through.
  PanelWindow {
    id: overlay
    visible: true
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
      width: root.ringRadius * 2
      height: root.ringRadius * 2
      radius: root.ringRadius
      color: "transparent"
      border.color: root.ringColor
      border.width: Math.max(2, root.ringRadius / 15)
      opacity: 0
      scale: 0.3

      // Position centered on cursor
      x: root.cursorX - width / 2
      y: root.cursorY - height / 2

      // Dark contrast ring immediately outside
      Rectangle {
        anchors.centerIn: parent
        width: parent.width + border.width * 2
        height: parent.height + border.width * 2
        radius: width / 2
        color: "transparent"
        border.color: Qt.rgba(0, 0, 0, 0.6)
        border.width: parent.border.width
      }

      // Dark contrast ring immediately inside
      Rectangle {
        anchors.centerIn: parent
        width: parent.width - border.width * 2
        height: parent.height - border.width * 2
        radius: width / 2
        color: "transparent"
        border.color: Qt.rgba(0, 0, 0, 0.6)
        border.width: parent.border.width
      }

      // Inner soft glow
      Rectangle {
        anchors.centerIn: parent
        width: parent.width / 2
        height: parent.height / 2
        radius: width / 2
        color: "transparent"
        border.color: root.ringColor
        border.width: 2
        opacity: 0.25
      }

      // Outer soft glow (black)
      Rectangle {
        anchors.centerIn: parent
        width: parent.width * 1.3
        height: parent.height * 1.3
        radius: width / 2
        color: "transparent"
        border.color: Qt.rgba(0, 0, 0, 0.15)
        border.width: root.ringRadius / 6
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
