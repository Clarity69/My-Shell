// Notification center: every notification this session, grouped by app.

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.services
import qs.notifications

Page {
    id: root

    pollInterval: 30000        // only to refresh the "5m", "1h" labels
    property int tick: 0
    onPoll: tick++

    PageHeader { kicker: "04 · system"; title: "Notifications" }

    SettingRow {
        icon: Notifications.dnd ? Icons.bellOff : Icons.bell
        title: "Do not disturb"
        sub: Notifications.dnd ? "Popups hidden, except critical" : "Popups shown"
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
        text: "No notifications yet. Try: notify-send \"Hello\" \"Test notification\""
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
