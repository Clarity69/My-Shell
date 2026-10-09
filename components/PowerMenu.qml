// Daftar aksi sesi. Edit `actions` untuk mengganti perintah (mis. hyprlock -> swaylock).

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config

ColumnLayout {
    id: root

    signal actionTriggered()

    readonly property var actions: [
        { icon: Icons.lock,    label: "Lock",     hint: "hyprlock",  danger: false,
          cmd: Config.lockCommand },
        { icon: Icons.suspend, label: "Suspend",  hint: "systemctl", danger: false,
          cmd: ["systemctl", "suspend"] },
        { icon: Icons.logout,  label: "Log out",  hint: "hyprctl",   danger: false,
          cmd: ["hyprctl", "dispatch", "exit"] },
        { icon: Icons.reboot,  label: "Restart",  hint: "systemctl", danger: true,
          cmd: ["systemctl", "reboot"] },
        { icon: Icons.power,   label: "Shut down", hint: "systemctl", danger: true,
          cmd: ["systemctl", "poweroff"] }
    ]

    Layout.fillWidth: true
    spacing: 2

    Repeater {
        model: root.actions

        Rectangle {
            id: row
            required property var modelData

            Layout.fillWidth: true
            implicitHeight: 38
            radius: Theme.radiusSmall
            color: mouse.containsMouse ? Theme.surface : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }

            readonly property color fg: modelData.danger ? Theme.danger : Theme.text

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 12

                Text {
                    text: row.modelData.icon
                    color: row.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.iconSize
                }
                Text {
                    Layout.fillWidth: true
                    text: row.modelData.label
                    color: row.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                }
                Text {
                    text: row.modelData.hint
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 10
                }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Quickshell.execDetached(row.modelData.cmd);
                    root.actionTriggered();
                }
            }
        }
    }
}
