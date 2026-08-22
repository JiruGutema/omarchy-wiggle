import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
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

  ColorDialog {
    id: colorDialog
    title: "Choose Ring Color"
    selectedColor: root.uiColor
    onAccepted: { root.uiColor = selectedColor; root.applyConfig(); }
  }

  PanelWindow {
    id: configPopup
    visible: root.popupOpened
    
    // Spans the whole screen to catch clicks outside the popup
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    WlrLayershell.namespace: "wiggle-finder-config"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.popupOpened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    
    // Allow clicking anywhere outside the box to close
    MouseArea {
      anchors.fill: parent
      onClicked: root.popupOpened = false
    }

    // The actual popup box
    Rectangle { 
      width: 260
      height: 310
      color: "#18181b"
      radius: 0
      border.color: "#3f3f46" 
      border.width: 1
      
      // Position near top right under the bar
      anchors.top: parent.top
      anchors.right: parent.right
      anchors.topMargin: root.bar ? root.bar.height + 5 : 40
      anchors.rightMargin: 10

      // Block clicks inside the box from closing it
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

          Label { text: "Ring Color"; color: "#d4d4d8"; font.pixelSize: 13 }
          
          Button {
            width: parent.width
            height: 30
            background: Rectangle {
              color: root.uiColor
              border.color: "#52525b"
              border.width: 1
              radius: 4
            }
            onClicked: {
              colorDialog.open()
            }
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
