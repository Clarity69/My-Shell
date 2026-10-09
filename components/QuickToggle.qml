// Tombol toggle berbentuk pil: ikon + label + sublabel (status).

import QtQuick
import QtQuick.Layouts
import qs.config

Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property string sublabel: ""
    property bool active: false
    property bool busy: false

    signal clicked()

    implicitHeight: 64
    radius: Theme.radius - 4
    color: active ? Theme.accent
         : mouse.containsMouse ? Theme.surface2 : Theme.surface
    opacity: enabled ? (busy ? 0.7 : 1) : 0.4
    Behavior on color   { ColorAnimation  { duration: 150 } }
    Behavior on opacity { NumberAnimation { duration: 150 } }

    readonly property color fg: active ? Theme.accentFg : Theme.text

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 12

        Text {
            id: iconText
            text: root.icon
            color: root.fg
            font.family: Theme.font
            font.pixelSize: Theme.iconSize + 2

            // Berkedip pelan selama perintah berjalan
            SequentialAnimation on opacity {
                running: root.busy
                loops: Animation.Infinite
                onRunningChanged: if (!running) iconText.opacity = 1
                NumberAnimation { to: 0.3; duration: 400 }
                NumberAnimation { to: 1;   duration: 400 }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: root.label
                color: root.fg
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                font.bold: true
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: root.sublabel
                color: root.fg
                opacity: 0.75
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 2
                elide: Text.ElideRight
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled && !root.busy
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
