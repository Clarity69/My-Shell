// Item navigasi sidebar. Aktif = blok krem dengan prefix "//".

import QtQuick
import QtQuick.Layouts
import qs.config

Rectangle {
    id: root

    property string label: ""
    property string hint: ""      // shortcut kecil di kanan
    property bool active: false

    signal clicked()

    Layout.fillWidth: true
    implicitHeight: 30
    radius: Theme.radiusSmall
    color: active ? Theme.accent
         : mouse.containsMouse ? Theme.surface : "transparent"
    Behavior on color { ColorAnimation { duration: 120 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10

        Text {
            Layout.fillWidth: true
            text: (root.active ? "// " : "") + root.label
            color: root.active ? Theme.accentFg : Theme.subtext
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 1
            elide: Text.ElideRight
        }

        Text {
            text: root.hint
            color: root.active ? Theme.accentFg : Theme.muted
            opacity: 0.7
            font.family: Theme.font
            font.pixelSize: 10
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
