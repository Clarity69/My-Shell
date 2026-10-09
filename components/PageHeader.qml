// Judul halaman: kicker kecil + judul serif.

import QtQuick
import QtQuick.Layouts
import qs.config

ColumnLayout {
    id: root

    property string kicker: ""
    property string title: ""

    Layout.fillWidth: true
    Layout.bottomMargin: 8
    spacing: 4

    Text {
        text: root.kicker.toUpperCase()
        color: Theme.muted
        font.family: Theme.font
        font.pixelSize: 10
        font.letterSpacing: 1.5
    }

    Text {
        Layout.fillWidth: true
        text: root.title
        color: Theme.text
        font.family: Theme.serif
        font.pixelSize: 40
        elide: Text.ElideRight
    }
}
