// "RESOLUTION ───────── 2560×1600 @ 165Hz"

import QtQuick
import QtQuick.Layouts
import qs.config

RowLayout {
    id: root

    property string key: ""
    property string value: ""

    Layout.fillWidth: true
    spacing: 10

    Text {
        text: root.key.toUpperCase()
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

    Text {
        Layout.maximumWidth: 280
        text: root.value !== "" ? root.value : "—"
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: Theme.fontSize - 1
        elide: Text.ElideLeft
    }
}
