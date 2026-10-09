// Angka telemetri: label kecil, nilai besar + unit, keterangan.

import QtQuick
import QtQuick.Layouts
import qs.config

ColumnLayout {
    id: root

    property string label: ""
    property string value: ""
    property string unit: ""
    property string sub: ""

    spacing: 2

    Text {
        text: root.label.toUpperCase()
        color: Theme.muted
        font.family: Theme.font
        font.pixelSize: 10
        font.letterSpacing: 1.5
    }

    Row {
        spacing: 3

        Text {
            id: valueText
            text: root.value
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 28
        }
        Text {
            anchors.baseline: valueText.baseline
            text: root.unit
            color: Theme.subtext
            font.family: Theme.font
            font.pixelSize: 14
        }
    }

    Text {
        text: root.sub
        color: Theme.muted
        font.family: Theme.font
        font.pixelSize: 10
        visible: text !== ""
    }
}
