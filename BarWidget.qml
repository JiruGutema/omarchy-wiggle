import QtQuick
import QtQuick.Controls
import qs.Ui
import QtCore

BarWidget {
  id: root
  moduleName: "dev.jirehn.wiggle-finder"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Settings {
    id: config
    category: "WiggleFinder"
    property string ringColor: "#ffffff"
    property int ringRadius: 60
    property int sensitivity: 3
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

        Label { text: "Ring Radius: " + config.ringRadius + "px"; color: "#d4d4d8"; font.pixelSize: 13 }
        Slider {
          width: parent.width
          from: 20
          to: 150
          stepSize: 5
          value: config.ringRadius
          onValueChanged: config.ringRadius = value
        }
      }

      Column {
        spacing: 5
        width: parent.width

        Label { text: "Color (Hex)"; color: "#d4d4d8"; font.pixelSize: 13 }
        TextField {
          width: parent.width
          text: config.ringColor
          color: "white"
          background: Rectangle {
            color: "#27272a"
            radius: 4
            border.color: "#52525b"
          }
          onTextChanged: config.ringColor = text
        }
      }

      Column {
        spacing: 5
        width: parent.width

        Label { text: "Shake Sensitivity: " + config.sensitivity; color: "#d4d4d8"; font.pixelSize: 13 }
        Label { text: "(lower = triggers easier)"; color: "#a1a1aa"; font.pixelSize: 11 }
        Slider {
          width: parent.width
          from: 2
          to: 8
          stepSize: 1
          value: config.sensitivity
          onValueChanged: config.sensitivity = value
        }
      }
    }
  }
}
