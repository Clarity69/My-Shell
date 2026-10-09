// Tombol teks kecil bergaris. `primary` = blok warna aksen.

import QtQuick
import qs.config

Rectangle {
    id: root

    property string text: ""
    property bool primary: false

    signal clicked()

    implicitWidth: label.implicitWidth + 24
    implicitHeight: 28
    radius: Theme.radiusSmall
    color: primary ? Theme.accent : (mouse.containsMouse ? Theme.surface2 : "transparent")
    border.color: primary ? Theme.accent : Theme.border
    opacity: enabled ? 1 : 0.4
    Behavior on color { ColorAnimation { duration: 120 } }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.primary ? Theme.accentFg : Theme.text
        font.family: Theme.font
        font.pixelSize: Theme.fontSize - 2
        font.letterSpacing: 0.5
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
