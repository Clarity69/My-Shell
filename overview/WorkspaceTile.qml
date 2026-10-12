// Satu workspace di overview: label + miniatur layar berisi window-window-nya.

import QtQuick
import QtQuick.Layouts
import qs.config

ColumnLayout {
    id: root

    required property int ws
    required property real tileW
    required property real tileH
    required property var mon
    required property string monName
    required property Item overlay
    property bool active: false
    property bool selected: false
    property bool dropTarget: false

    readonly property bool hovered: hover.hovered
    readonly property var windows: OverviewState.windowsOn(ws)
    readonly property real sx: tileW / Math.max(1, mon.w)
    readonly property real sy: tileH / Math.max(1, mon.h)

    signal dragStarted(var client)
    signal dragMoved(point pos)
    signal dragEnded()

    spacing: 6

    HoverHandler { id: hover }

    // Label
    RowLayout {
        Layout.preferredWidth: root.tileW
        spacing: 8

        Text {
            text: root.ws
            color: root.active ? Theme.text : Theme.subtext
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            font.bold: root.active
        }
        Text {
            Layout.fillWidth: true
            text: root.windows.length > 0 ? root.windows.length + (root.windows.length === 1 ? " window" : " windows") : "empty"
            color: Theme.muted
            font.family: Theme.font
            font.pixelSize: 10
            elide: Text.ElideRight
        }
    }

    // Miniatur layar
    Rectangle {
        id: screenRect
        Layout.preferredWidth: root.tileW
        Layout.preferredHeight: root.tileH
        radius: Theme.radius
        color: Theme.surface
        clip: true
        border.width: root.dropTarget || root.selected || root.active ? 2 : 1
        border.color: root.dropTarget ? Theme.rose
                    : root.selected ? Theme.accent
                    : root.active ? Theme.subtext : Theme.border
        Behavior on border.color { ColorAnimation { duration: 120 } }

        // Klik workspace kosong / latar = pindah ke workspace ini
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: OverviewState.goTo(root.ws)
        }

        Text {
            anchors.centerIn: parent
            visible: root.windows.length === 0
            text: "+"
            color: Theme.muted
            font.family: Theme.font
            font.pixelSize: 28
        }

        Repeater {
            model: root.windows

            WindowThumb {
                required property var modelData
                client: modelData
                x: (modelData.x - root.mon.x) * root.sx
                y: (modelData.y - root.mon.y) * root.sy
                width: Math.max(24, modelData.w * root.sx)
                height: Math.max(18, modelData.h * root.sy)
                z: modelData.floating ? 2 : 1
                overlay: root.overlay
                onDragStarted: c => root.dragStarted(c)
                onDragMoved: p => root.dragMoved(p)
                onDragEnded: root.dragEnded()
            }
        }
    }
}
