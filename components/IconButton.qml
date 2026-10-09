// Tombol bulat berisi satu glyph ikon. Dipakai di Header, PowerMenu, SliderRow.

import QtQuick
import qs.config

Rectangle {
    id: root

    property string icon: ""
    property color iconColor: Theme.text
    property color baseColor: "transparent"
    property color hoverColor: Theme.surface2
    property int size: 36

    signal clicked()

    implicitWidth: size
    implicitHeight: size
    radius: size / 2
    color: mouse.containsMouse ? hoverColor : baseColor
    Behavior on color { ColorAnimation { duration: 120 } }

    Text {
        anchors.centerIn: parent
        text: root.icon
        color: root.iconColor
        font.family: Theme.font
        font.pixelSize: Theme.iconSize
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
