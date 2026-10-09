// Baris pengaturan: judul + keterangan di kiri, kontrol (Switch, tombol) di kanan.

import QtQuick
import QtQuick.Layouts
import qs.config

RowLayout {
    id: root

    property string icon: ""
    property string title: ""
    property string sub: ""

    default property alias control: slot.data

    Layout.fillWidth: true
    spacing: 12

    Text {
        visible: root.icon !== ""
        text: root.icon
        color: Theme.subtext
        font.family: Theme.font
        font.pixelSize: Theme.iconSize
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 1

        Text {
            Layout.fillWidth: true
            text: root.title
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            elide: Text.ElideRight
        }
        Text {
            Layout.fillWidth: true
            visible: text !== ""
            text: root.sub
            color: Theme.muted
            font.family: Theme.font
            font.pixelSize: 10
            elide: Text.ElideRight
        }
    }

    RowLayout {
        id: slot
        spacing: 8
    }
}
