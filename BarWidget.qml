import QtQuick
import QtQuick.Controls
import qs.Ui
import "ShakeDetector.js" as Shake

BarWidget {
  id: root
  moduleName: "dev.jirehn.wiggle-finder"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

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
        if (configPopup.opened) {
          configPopup.close()
        } else {
          configPopup.open()
        }
      }
    }
  }

  Popup {
    id: configPopup
    width: 260
    height: 310
    y: root.bar ? root.bar.height + 5 : 30
    x: button.mapToItem(null, 0, 0).x - width/2 + button.width/2
    padding: 15
    background: Rectangle { 
      color: "#18181b"
      radius: 10
      border.color: "#3f3f46" 
      border.width: 1
    }

    Column {
      spacing: 20
      anchors.fill: parent

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
