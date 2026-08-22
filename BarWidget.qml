import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import qs.Ui
import qs.Commons
import "ShakeDetector.js" as Shake

Panel {
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
      if (btn === Qt.LeftButton) root.toggle()
    }
  }

  ColorDialog {
    id: colorDialog
    title: "Choose Ring Color"
    selectedColor: root.uiColor
    onAccepted: { root.uiColor = selectedColor; root.applyConfig(); }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    
    contentWidth: panel.fittedContentWidth(Style.space(260))
    contentHeight: panel.fittedContentHeight(mainColumn.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      
      Column {
        id: mainColumn
        width: parent.width
        spacing: Style.space(24)
        
        PanelSectionHeader {
          text: "WIGGLE FINDER"
          foreground: root.bar.foreground
          fontFamily: root.bar.fontFamily
        }

        Column {
          spacing: Style.space(6)
          width: parent.width

          Text { 
            text: "RING RADIUS: " + root.uiRadius + "px"
            color: Qt.darker(root.bar.foreground, 1.2)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
          }
          PanelSlider {
            bar: root.bar
            width: parent.width
            minimum: 20
            maximum: 150
            step: 5
            value: root.uiRadius
            onMoved: function(v) { root.uiRadius = v; root.applyConfig(); }
          }
        }

        Column {
          spacing: Style.space(6)
          width: parent.width

          Text { 
            text: "RING COLOR"
            color: Qt.darker(root.bar.foreground, 1.2)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
          }
          
          Rectangle {
            width: parent.width
            height: Style.space(32)
            color: root.uiColor
            border.color: Util.alpha(root.bar.foreground, 0.2)
            border.width: 1
            radius: Style.radius.panel
            
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: colorDialog.open()
            }
          }
        }

        Column {
          spacing: Style.space(6)
          width: parent.width

          Text { 
            text: "SHAKE SENSITIVITY: " + root.uiSensitivity
            color: Qt.darker(root.bar.foreground, 1.2)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
          }
          PanelSlider {
            bar: root.bar
            width: parent.width
            minimum: 2
            maximum: 8
            step: 1
            value: root.uiSensitivity
            onMoved: function(v) { root.uiSensitivity = v; root.applyConfig(); }
          }
        }
      }
    }
  }
}
