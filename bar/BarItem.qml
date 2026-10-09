// Item bar: ikon + label opsional. Klik kiri/kanan dan scroll.

import QtQuick
import QtQuick.Layouts
import qs.config

Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property color iconColor: Theme.text
    property bool dimmed: false

    signal clicked()
    signal rightClicked()
    signal scrolled(int delta)

    implicitWidth: row.implicitWidth + 16
    implicitHeight: Theme.barHeight - 8
    radius: Theme.radiusSmall
    color: mouse.containsMouse ? Theme.surface : "transparent"
    opacity: dimmed ? 0.55 : 1
    Behavior on color { ColorAnimation { duration: 120 } }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: root.icon
            color: root.iconColor
            font.family: Theme.font
            font.pixelSize: Theme.iconSize - 3
        }
        Text {
            visible: root.label !== ""
            Layout.maximumWidth: 140
            text: root.label
            color: Theme.subtext
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 2
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => mouse.button === Qt.RightButton ? root.rightClicked() : root.clicked()
        onWheel: wheel => root.scrolled(wheel.angleDelta.y)
    }
}
