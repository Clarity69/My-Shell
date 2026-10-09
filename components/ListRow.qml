// Baris daftar: ikon, judul, subjudul, teks kanan. Aktif = garis aksen di kiri.
// Child tambahan (mis. kolom password) tampil di bawah baris.

import QtQuick
import QtQuick.Layouts
import qs.config

Rectangle {
    id: root

    property string icon: ""
    property string title: ""
    property string sub: ""
    property string trailing: ""
    property bool active: false
    property bool busy: false
    property bool interactive: true

    default property alias extra: extraCol.data

    signal clicked()

    Layout.fillWidth: true
    implicitHeight: col.implicitHeight + 16
    radius: Theme.radiusSmall
    color: active || (interactive && mouse.containsMouse) ? Theme.surface : "transparent"
    Behavior on color { ColorAnimation { duration: 120 } }

    // Dideklarasikan pertama agar input di `extra` tetap bisa diklik
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: root.interactive
        enabled: root.interactive
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    Rectangle {
        visible: root.active
        width: 2
        height: 18
        radius: 1
        x: 0
        y: 8 + (rowMain.implicitHeight - height) / 2
        color: Theme.accent
    }

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 8
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 8

        RowLayout {
            id: rowMain
            Layout.fillWidth: true
            spacing: 12

            Text {
                id: iconPulse
                visible: root.icon !== ""
                text: root.icon
                color: root.active ? Theme.text : Theme.subtext
                font.family: Theme.font
                font.pixelSize: Theme.iconSize

                SequentialAnimation on opacity {
                    running: root.busy
                    loops: Animation.Infinite
                    onRunningChanged: if (!running) iconPulse.opacity = 1
                    NumberAnimation { to: 0.3; duration: 400 }
                    NumberAnimation { to: 1; duration: 400 }
                }
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

            Text {
                visible: text !== ""
                text: root.trailing
                color: root.active ? Theme.subtext : Theme.muted
                font.family: Theme.font
                font.pixelSize: 10
            }
        }

        ColumnLayout {
            id: extraCol
            Layout.fillWidth: true
            spacing: 8
            visible: visibleChildren.length > 0
        }
    }
}
