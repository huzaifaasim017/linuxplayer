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
    property color accentColor: "#64d5c6"

    implicitWidth: 44
    implicitHeight: 44
    hoverEnabled: true

    background: Rectangle {
        radius: control.prominent ? 14 : 12
        color: control.down ? "#56ffffff"
              : control.prominent ? (control.hovered ? Qt.rgba(control.accentColor.r, control.accentColor.g, control.accentColor.b, 0.53)
                                                  : Qt.rgba(control.accentColor.r, control.accentColor.g, control.accentColor.b, 0.38))
              : control.hovered || control.activeFocus ? "#29ffffff"
              : control.selected ? Qt.rgba(control.accentColor.r, control.accentColor.g, control.accentColor.b, 0.22) : "transparent"
        border.width: control.activeFocus ? 2 : control.prominent ? 1 : 0
        border.color: control.accentColor
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
