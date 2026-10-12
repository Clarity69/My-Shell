// Pusat notifikasi: semua notifikasi sesi ini, dikelompokkan per aplikasi.

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.services
import qs.notifications

Page {
    id: root

    pollInterval: 30000        // hanya untuk menyegarkan label "5m", "1h"
    property int tick: 0
    onPoll: tick++

    PageHeader { kicker: "04 · system"; title: "Notifications" }

    SettingRow {
        icon: Notifications.dnd ? Icons.bellOff : Icons.bell
        title: "Do not disturb"
        sub: Notifications.dnd ? "Popup disembunyikan, kecuali critical" : "Popup tampil"
        Switch { checked: Notifications.dnd; onToggled: Notifications.toggle() }
    }

    RowLayout {
        Layout.fillWidth: true
        SectionLabel { text: Notifications.count + " notifications" }
        TextButton {
            text: "Clear all"
            enabled: Notifications.count > 0
            onClicked: Notifications.clearAll()
        }
    }

    Hint {
        visible: Notifications.count === 0
        text: "Belum ada notifikasi. Coba: notify-send \"Halo\" \"Tes notifikasi\""
    }

    Repeater {
        model: Notifications.groups

        ColumnLayout {
            id: group
            required property var modelData
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6

                Text {
                    Layout.fillWidth: true
                    text: group.modelData.app + "  ·  " + group.modelData.items.length
                    color: Theme.subtext
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 1
                    font.bold: true
                }
                TextButton {
                    text: "Clear"
                    onClicked: group.modelData.items.slice().forEach(n => Notifications.dismiss(n))
                }
            }

            Repeater {
                model: group.modelData.items

                NotifCard {
                    required property var modelData
                    Layout.fillWidth: true
                    compact: true
                    notif: modelData
                    refreshTick: root.tick
                }
            }
        }
    }
}
