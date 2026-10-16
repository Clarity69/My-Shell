pragma Singleton

import QtQuick
import Quickshell

// Warna & font dynamic island (island/Island.qml).
// Default hitam-putih seperti Tide Island; aksen (equalizer, titik notif) ikut pywal.
Singleton {
    readonly property color bg: Config.islandUseTheme ? Theme.bg : "#000000"
    readonly property color fg: Config.islandUseTheme ? Theme.text : "#ffffff"
    readonly property color dim: Qt.rgba(fg.r, fg.g, fg.b, 0.55)
    readonly property color faint: Qt.rgba(fg.r, fg.g, fg.b, 0.18)
    readonly property color accent: Theme.rose
    readonly property string font: Config.islandFont
}
