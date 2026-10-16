// Bluetooth: power + paired devices (click to connect/disconnect).

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
        sub: !Bluetooth.available ? "No adapter"
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
        text: "No paired devices yet. Pair one with bluetoothctl or blueman and it will show up here."
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
