// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Window
import QtQuick.Controls

AbstractButton {
    id: control

    property string iconName: ""
    property int iconSize: 20
    property bool selected: false
    property bool prominent: false

    implicitWidth: 44
    implicitHeight: 44
    hoverEnabled: true

    background: Rectangle {
        radius: control.prominent ? 14 : 12
        color: control.down ? "#70ffffff"
              : control.prominent ? (control.hovered ? "#738fbaff" : "#567fa9ff")
              : control.hovered || control.activeFocus ? "#28ffffff"
              : control.selected ? "#237fa9ff" : "transparent"
        border.width: control.activeFocus ? 2 : control.prominent ? 1 : 0
        border.color: control.activeFocus ? "#b9d2ff" : "#7fb0ff"
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    contentItem: Item {
        Image {
            anchors.centerIn: parent
            width: control.iconSize
            height: control.iconSize
            source: "../icons/" + control.iconName + ".svg"
            // Rasterize SVGs for the display, then keep their intended logical size.
            sourceSize.width: Math.ceil(control.iconSize * Screen.devicePixelRatio)
            sourceSize.height: Math.ceil(control.iconSize * Screen.devicePixelRatio)
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            opacity: control.enabled ? 1 : 0.38
            Behavior on opacity { NumberAnimation { duration: 130 } }
        }
    }
}
