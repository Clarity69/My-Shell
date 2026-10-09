// Ikon (bisa diklik) + slider horizontal 0..1 + persentase.
// Selama di-drag, slider memakai nilai lokal sehingga polling dari service
// tidak membuat handle "meloncat" kembali.

import QtQuick
import QtQuick.Layouts
import qs.config

RowLayout {
    id: root

    property string icon: ""
    property real value: 0          // dari service, 0..1
    property bool dimmed: false     // mis. saat mute

    signal moved(real v)
    signal iconClicked()

    property real dragValue: 0
    readonly property bool dragging: area.pressed
    readonly property real shown: dragging ? dragValue : Math.max(0, Math.min(1, value))

    spacing: 10

    IconButton {
        icon: root.icon
        iconColor: root.dimmed ? Theme.subtext : Theme.text
        size: 32
        onClicked: root.iconClicked()
    }

    Item {
        id: track
        Layout.fillWidth: true
        implicitHeight: 24

        Rectangle {               // jalur
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 8
            radius: 4
            color: Theme.surface2

            Rectangle {           // isi
                width: Math.max(height, parent.width * root.shown)
                height: parent.height
                radius: 4
                color: root.dimmed ? Theme.subtext : Theme.accent
            }
        }

        Rectangle {               // handle
            width: 18
            height: 18
            radius: 9
            anchors.verticalCenter: parent.verticalCenter
            x: (track.width - width) * root.shown
            color: Theme.text
            scale: root.dragging ? 1.15 : 1
            Behavior on scale { NumberAnimation { duration: 100 } }
        }

        MouseArea {
            id: area
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            preventStealing: true

            function update(mx) {
                root.dragValue = Math.max(0, Math.min(1, mx / width));
                root.moved(root.dragValue);
            }
            onPressed: mouse => update(mouse.x)
            onPositionChanged: mouse => { if (pressed) update(mouse.x) }

            // Scroll = langkah 5%
            onWheel: wheel => {
                const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                root.moved(Math.max(0, Math.min(1, root.value + step)));
            }
        }
    }

    Text {
        Layout.preferredWidth: 40
        horizontalAlignment: Text.AlignRight
        text: Math.round(root.shown * 100) + "%"
        color: Theme.subtext
        font.family: Theme.font
        font.pixelSize: Theme.fontSize - 1
    }
}
