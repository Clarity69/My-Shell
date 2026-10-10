// Daftar aksi sesi. Edit `actions` untuk mengganti perintah (mis. hyprlock -> swaylock).
// Aksi dengan confirm: true butuh klik kedua dalam `confirmSeconds` detik.

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config

ColumnLayout {
    id: root

    signal actionTriggered()

    readonly property int confirmSeconds: 5

    readonly property var actions: [
        { icon: Icons.lock,    label: "Lock",      hint: "hyprlock",  danger: false, confirm: false,
          cmd: Config.lockCommand },
        { icon: Icons.suspend, label: "Suspend",   hint: "systemctl", danger: false, confirm: false,
          cmd: ["systemctl", "suspend"] },
        { icon: Icons.logout,  label: "Log out",   hint: "hyprctl",   danger: false, confirm: true,
          cmd: ["hyprctl", "dispatch", "exit"] },
        { icon: Icons.reboot,  label: "Restart",   hint: "systemctl", danger: true,  confirm: true,
          cmd: ["systemctl", "reboot"] },
        { icon: Icons.power,   label: "Shut down", hint: "systemctl", danger: true,  confirm: true,
          cmd: ["systemctl", "poweroff"] }
    ]

    // Aksi yang sedang menunggu konfirmasi (-1 = tidak ada)
    property int pending: -1
    property int remaining: 0

    function cancel() { pending = -1; countdown.stop(); }

    function trigger(i) {
        const a = actions[i];
        if (a.confirm && pending !== i) {
            pending = i;
            remaining = confirmSeconds;
            countdown.restart();
            return;
        }
        cancel();
        Quickshell.execDetached(a.cmd);
        actionTriggered();
    }

    // Batalkan otomatis setelah hitung mundur, atau saat halaman ditinggalkan
    onVisibleChanged: if (!visible) cancel()

    Timer {
        id: countdown
        interval: 1000
        repeat: true
        onTriggered: {
            root.remaining--;
            if (root.remaining <= 0) root.cancel();
        }
    }

    Layout.fillWidth: true
    spacing: 2

    Repeater {
        model: root.actions

        Rectangle {
            id: row
            required property var modelData
            required property int index
            readonly property bool armed: root.pending === index

            Layout.fillWidth: true
            implicitHeight: 38
            radius: Theme.radiusSmall
            color: armed ? Theme.danger
                 : mouse.containsMouse ? Theme.surface : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }

            readonly property color fg: armed ? Theme.accentFg
                                      : modelData.danger ? Theme.danger : Theme.text

            // Bilah sisa waktu konfirmasi
            Rectangle {
                visible: row.armed
                anchors.bottom: parent.bottom
                height: 2
                radius: 1
                color: Theme.accentFg
                opacity: 0.5
                width: parent.width * root.remaining / root.confirmSeconds
                Behavior on width { NumberAnimation { duration: 1000 } }
            }

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
                    text: row.armed ? "Klik lagi untuk " + row.modelData.label.toLowerCase()
                                    : row.modelData.label
                    color: row.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    font.bold: row.armed
                }
                Text {
                    text: row.armed ? root.remaining + "s · esc batal" : row.modelData.hint
                    color: row.armed ? row.fg : Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 10
                }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.trigger(row.index)
            }
        }
    }
}
