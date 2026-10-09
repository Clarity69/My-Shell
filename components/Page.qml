// Kerangka halaman: area scroll + polling selama halaman aktif.
//   active        : diset ControlCenter (window terlihat && halaman ini dipilih)
//   pollInterval  : 0 = tidak polling
//   opened()      : sekali setiap halaman dibuka
//   poll()        : berkala selama aktif
// Isi halaman ditulis langsung sebagai child; otomatis masuk ColumnLayout.

import QtQuick
import QtQuick.Layouts
import qs.config

Item {
    id: root

    property bool active: false
    property int pollInterval: 2000
    readonly property real innerWidth: col.width

    signal opened()
    signal poll()

    default property alias content: col.data

    onActiveChanged: if (active) opened()

    Timer {
        interval: Math.max(500, root.pollInterval)
        repeat: true
        running: root.active && root.pollInterval > 0
        triggeredOnStart: true
        onTriggered: root.poll()
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        ColumnLayout {
            id: col
            width: flick.width - 14     // ruang untuk indikator scroll
            spacing: 14
        }
    }

    // Indikator scroll tipis
    Rectangle {
        visible: flick.contentHeight > flick.height
        anchors.right: parent.right
        width: 3
        radius: 1.5
        color: Theme.surface2
        height: Math.max(24, flick.height * flick.height / Math.max(1, flick.contentHeight))
        y: flick.contentY / Math.max(1, flick.contentHeight - flick.height) * (flick.height - height)
    }
}
