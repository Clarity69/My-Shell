// Satu kelompok modul (kiri, tengah, atau kanan).
// Gaya "islands": kelompok ini punya latar & radius sendiri.

import QtQuick
import QtQuick.Layouts
import qs.config

Rectangle {
    id: sec

    required property var specs
    required property var monitor
    required property var window
    required property var layout

    signal openPage(string name)
    signal toggleControl()

    readonly property bool island: layout.style === "islands"

    visible: specs.length > 0
    implicitWidth: row.implicitWidth + (island ? 12 : 0)
    implicitHeight: layout.height
    color: island ? Theme.bg : "transparent"
    radius: island ? layout.radius : 0
    border.width: island ? 1 : 0
    border.color: Theme.border

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: sec.layout.style === "border" ? 6 : 2

        Repeater {
            model: sec.specs

            Module {
                required property string modelData
                spec: modelData
                monitor: sec.monitor
                window: sec.window
                layout: sec.layout
                onOpenPage: n => sec.openPage(n)
                onToggleControl: sec.toggleControl()
            }
        }
    }
}
