// Kolom teks satu baris dengan placeholder dan ikon opsional.

import QtQuick
import QtQuick.Layouts
import qs.config

Rectangle {
    id: root

    property alias text: input.text
    property string placeholder: ""
    property string icon: ""
    property bool password: false

    signal accepted()

    function forceFocus() { input.forceActiveFocus(); }

    Layout.fillWidth: true
    implicitHeight: 32
    radius: Theme.radiusSmall
    color: Theme.surface
    border.color: input.activeFocus ? Theme.subtext : Theme.border
    Behavior on border.color { ColorAnimation { duration: 120 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 8

        Text {
            visible: root.icon !== ""
            text: root.icon
            color: Theme.muted
            font.family: Theme.font
            font.pixelSize: 14
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            TextInput {
                id: input
                anchors.fill: parent
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.text
                selectionColor: Theme.surface2
                selectedTextColor: Theme.text
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 1
                echoMode: root.password ? TextInput.Password : TextInput.Normal
                selectByMouse: true
                clip: true
                onAccepted: root.accepted()
            }

            Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                visible: input.text === ""
                text: root.placeholder
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 1
                elide: Text.ElideRight
            }
        }
    }
}
