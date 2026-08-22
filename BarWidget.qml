import QtQuick
import QtQuick.Controls
import qs.Ui
import Quickshell
import Quickshell.Wayland
import "ShakeDetector.js" as Shake

BarWidget {
  id: root
  moduleName: "dev.jirehn.wiggle-finder"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  
  property bool popupOpened: false
  // Local state for UI
  property int uiRadius: 60
  property string uiColor: "#ffffff"
  property int uiSensitivity: 3

  Component.onCompleted: {
    uiRadius = Shake.config.ringRadius;
    uiColor = Shake.config.ringColor;
    uiSensitivity = Shake.config.sensitivity;
    
    Shake.addListener(function() {
      uiRadius = Shake.config.ringRadius;
      uiColor = Shake.config.ringColor;
      uiSensitivity = Shake.config.sensitivity;
    });
  }

  function applyConfig() {
    Shake.updateConfig(uiRadius, uiColor, uiSensitivity);
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "〰️"
    onPressed: function(btn) {
      if (btn === Qt.LeftButton) {
        root.popupOpened = !root.popupOpened;
      }
    }
  }

  PanelWindow {
    id: configPopup
    visible: root.popupOpened
    
    // Position near the top right, under the bar
    anchors { top: true; right: true }
    margins {
      top: root.bar ? root.bar.height + 5 : 40
      right: 10
    }
    
    width: 260
    height: 310
    color: "transparent"

    WlrLayershell.namespace: "wiggle-finder-config"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.popupOpened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    
    // Allow clicking outside to close
    MouseArea {
      anchors.fill: parent
      onClicked: root.popupOpened = false
    }

    Rectangle { 
      anchors.fill: parent
      color: "#18181b"
      radius: 10
      border.color: "#3f3f46" 
      border.width: 1

      // Block clicks from closing the popup if they click inside the menu
      MouseArea {
        anchors.fill: parent
        onClicked: {}
      }

      Column {
        spacing: 20
        anchors.fill: parent
        anchors.margins: 15

        Label { 
          text: "Wiggle Finder"
          color: "white"
          font.bold: true
          font.pixelSize: 16
          anchors.horizontalCenter: parent.horizontalCenter
        }

        Column {
          spacing: 5
          width: parent.width

          Label { text: "Ring Radius: " + root.uiRadius + "px"; color: "#d4d4d8"; font.pixelSize: 13 }
          Slider {
            width: parent.width
            from: 20
            to: 150
            stepSize: 5
            value: root.uiRadius
            onValueChanged: { root.uiRadius = value; root.applyConfig(); }
          }
        }

        Column {
          spacing: 5
          width: parent.width

          Label { text: "Color (Hex)"; color: "#d4d4d8"; font.pixelSize: 13 }
          TextField {
            width: parent.width
            text: root.uiColor
            color: "white"
            background: Rectangle {
              color: "#27272a"
              radius: 4
              border.color: "#52525b"
            }
            onTextChanged: { root.uiColor = text; root.applyConfig(); }
          }
        }

        Column {
          spacing: 5
          width: parent.width

          Label { text: "Shake Sensitivity: " + root.uiSensitivity; color: "#d4d4d8"; font.pixelSize: 13 }
          Label { text: "(lower = triggers easier)"; color: "#a1a1aa"; font.pixelSize: 11 }
          Slider {
            width: parent.width
            from: 2
            to: 8
            stepSize: 1
            value: root.uiSensitivity
            onValueChanged: { root.uiSensitivity = value; root.applyConfig(); }
          }
        }
      }
    }
  }
}
