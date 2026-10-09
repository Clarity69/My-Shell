// Teks keterangan kecil yang membungkus (wrap).

import QtQuick
import QtQuick.Layouts
import qs.config

Text {
    property bool warn: false

    Layout.fillWidth: true
    wrapMode: Text.WordWrap
    color: warn ? Theme.rose : Theme.muted
    font.family: Theme.font
    font.pixelSize: Theme.fontSize - 2
    lineHeight: 1.2
}
