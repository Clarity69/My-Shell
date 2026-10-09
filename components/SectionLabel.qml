// Label kecil "01  OVERVIEW ─────────"

import QtQuick
import QtQuick.Layouts
import qs.config

RowLayout {
    id: root

    property string number: ""
    property string text: ""

    Layout.fillWidth: true
    spacing: 8

    Text {
        text: (root.number !== "" ? root.number + "  " : "") + root.text.toUpperCase()
        color: Theme.muted
        font.family: Theme.font
        font.pixelSize: 10
        font.letterSpacing: 1.5
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 1
        color: Theme.border
    }
}
