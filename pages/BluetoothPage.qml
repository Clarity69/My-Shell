// Bluetooth: power + perangkat ter-pair (klik untuk connect/disconnect).

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.services

Page {
    onPoll: Bluetooth.refresh()

    PageHeader { kicker: "02 · devices"; title: "Bluetooth" }

    SettingRow {
        icon: Bluetooth.powered ? Icons.bluetooth : Icons.bluetoothOff
        title: "Bluetooth"
        sub: !Bluetooth.available ? "Tidak ada adapter"
           : !Bluetooth.powered ? "Off"
           : Bluetooth.device !== "" ? "Connected to " + Bluetooth.device : "On"

        Switch {
            checked: Bluetooth.powered
            enabled: Bluetooth.available && !Bluetooth.busy
            onToggled: Bluetooth.toggle()
        }
    }

    SectionLabel { Layout.topMargin: 6; text: "paired devices" }

    Hint {
        visible: Bluetooth.devices.length === 0
        text: "Belum ada perangkat ter-pair. Pair dulu lewat bluetoothctl atau blueman, lalu perangkat muncul di sini."
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Repeater {
            model: Bluetooth.devices

            ListRow {
                required property var modelData

                enabled: Bluetooth.powered
                opacity: Bluetooth.powered ? 1 : 0.5
                icon: modelData.connected ? Icons.bluetoothOn : Icons.bluetooth
                title: modelData.name
                sub: modelData.mac
                trailing: Bluetooth.pending === modelData.mac ? "…"
                        : modelData.connected ? "connected" : "connect"
                active: modelData.connected
                busy: Bluetooth.pending === modelData.mac
                onClicked: Bluetooth.toggleDevice(modelData)
            }
        }
    }
}
