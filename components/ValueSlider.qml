// Slider bilangan bulat berlabel: "ROUNDING ............ 10px"
//   moved(v)     : setiap nilai berubah saat di-drag
//   committed(v) : saat dilepas (untuk aksi mahal, mis. restart hyprsunset)

import QtQuick
import QtQuick.Layouts
import qs.config

ColumnLayout {
    id: root

    property string label: ""
    property int from: 0
    property int to: 100
    property int step: 1
    property int value: 0
    property string suffix: ""

    signal moved(int v)
    signal committed(int v)

    property int dragValue: 0
    readonly property bool dragging: area.pressed
    readonly property int shown: dragging ? dragValue : value
    readonly property real ratio: (shown - from) / Math.max(1, to - from)

    Layout.fillWidth: true
    spacing: 6
    opacity: enabled ? 1 : 0.4

    RowLayout {
        Layout.fillWidth: true

        Text {
            Layout.fillWidth: true
            text: root.label.toUpperCase()
            color: Theme.muted
            font.family: Theme.font
            font.pixelSize: 10
            font.letterSpacing: 1.5
        }
        Text {
            text: root.shown + root.suffix
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 1
        }
    }

    Item {
        id: track
        Layout.fillWidth: true
        implicitHeight: 16

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 4
            radius: 2
            color: Theme.surface2

            Rectangle {
                width: parent.width * root.ratio
                height: parent.height
                radius: 2
                color: Theme.accent
            }
        }

        Rectangle {
            width: 12
            height: 12
            radius: 6
            anchors.verticalCenter: parent.verticalCenter
            x: (track.width - width) * root.ratio
            color: Theme.text
            scale: root.dragging ? 1.2 : 1
            Behavior on scale { NumberAnimation { duration: 100 } }
        }

        MouseArea {
            id: area
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            preventStealing: true

            function pick(mx) {
                const raw = root.from + Math.max(0, Math.min(1, mx / width)) * (root.to - root.from);
                const v = Math.round(raw / root.step) * root.step;
                if (v !== root.dragValue || !pressed) {
                    root.dragValue = v;
                    root.moved(v);
                }
            }
            onPressed: mouse => { root.dragValue = root.value; pick(mouse.x); }
            onPositionChanged: mouse => { if (pressed) pick(mouse.x); }
            onReleased: root.committed(root.dragValue)
        }
    }
}
