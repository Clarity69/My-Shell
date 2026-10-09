// Saklar kecil on/off.

import QtQuick
import qs.config

Rectangle {
    id: root

    property bool checked: false
    signal toggled()

    implicitWidth: 36
    implicitHeight: 20
    radius: height / 2
    color: checked ? Theme.accent : Theme.surface2
    opacity: enabled ? 1 : 0.4
    Behavior on color { ColorAnimation { duration: 140 } }

    Rectangle {
        width: 14
        height: 14
        radius: 7
        y: 3
        x: root.checked ? root.width - width - 3 : 3
        color: root.checked ? Theme.accentFg : Theme.subtext
        Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
