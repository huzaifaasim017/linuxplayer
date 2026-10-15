// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls

AbstractButton {
    id: control

    property string iconName: ""
    property int iconSize: 20
    property color accentColor: "#f5f7fa"
    property bool selected: false

    implicitWidth: 42
    implicitHeight: 42
    hoverEnabled: true

    background: Rectangle {
        radius: width / 2
        color: control.down ? "#3bffffff" : control.hovered || control.activeFocus ? "#25ffffff" : control.selected ? "#20ffffff" : "transparent"
        border.width: control.activeFocus ? 2 : 0
        border.color: "#a5c5ff"
        Behavior on color { ColorAnimation { duration: 130 } }
    }

    contentItem: Image {
        source: "../icons/" + control.iconName + ".svg"
        sourceSize.width: control.iconSize
        sourceSize.height: control.iconSize
        width: control.iconSize
        height: control.iconSize
        anchors.centerIn: parent
        fillMode: Image.PreserveAspectFit
        opacity: control.enabled ? 1 : 0.38
        Behavior on opacity { NumberAnimation { duration: 130 } }
    }
}
