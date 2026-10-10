// Profil: hostname besar, telemetri live, quick settings, info sistem.

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.components
import qs.services

Page {
    id: root

    onPoll: {
        SystemInfo.refresh();
        SystemStats.refresh();
        Battery.refresh();
        Network.refresh();
        Bluetooth.refresh();
        NightLight.refresh();
        Notifications.refresh();
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property var down: SystemStats.formatRate(SystemStats.rxRate)
    readonly property var up: SystemStats.formatRate(SystemStats.txRate)

    // ── Identitas ────────────────────────────────────────────────────
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Text {
            text: "SYSTEM · DOSSIER"
            color: Theme.muted
            font.family: Theme.font
            font.pixelSize: 10
            font.letterSpacing: 1.5
        }
        Text {
            Layout.fillWidth: true
            text: SystemInfo.host
            color: Theme.text
            font.family: Theme.serif
            font.pixelSize: 60
            elide: Text.ElideRight
        }
        Text {
            text: "@" + SystemInfo.user + "  ·  " + Qt.formatDateTime(clock.date, "hh:mm")
            color: Theme.subtext
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 1
        }
        Text {
            visible: text !== ""
            text: SystemInfo.os
            color: Theme.subtext
            font.family: Theme.serif
            font.italic: true
            font.pixelSize: Theme.fontSize + 1
        }
    }

    // ── Telemetri ────────────────────────────────────────────────────
    SectionLabel { Layout.topMargin: 6; text: "live telemetry" }

    GridLayout {
        Layout.fillWidth: true
        columns: 4
        columnSpacing: 20

        StatBlock {
            Layout.fillWidth: true
            label: "core"
            value: SystemStats.temp > 0 ? SystemStats.temp : "—"
            unit: SystemStats.temp > 0 ? "°C" : ""
            sub: "cpu temp"
        }
        StatBlock {
            Layout.fillWidth: true
            label: "cpu"
            value: Math.round(SystemStats.cpu * 100)
            unit: "%"
            sub: "load"
        }
        StatBlock {
            Layout.fillWidth: true
            label: "memory"
            value: Math.round(SystemStats.mem * 100)
            unit: "%"
            sub: SystemStats.formatKiB(SystemStats.memUsed) + " / " + SystemStats.formatKiB(SystemStats.memTotal)
        }
        StatBlock {
            Layout.fillWidth: true
            label: "network"
            value: "↓ " + root.down.v
            unit: root.down.u
            sub: "↑ " + root.up.v + " " + root.up.u
        }
    }

    // Riwayat CPU sebagai batang tipis
    Item {
        Layout.fillWidth: true
        implicitHeight: 28

        Row {
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            spacing: 3

            Repeater {
                model: SystemStats.history
                Rectangle {
                    required property real modelData
                    anchors.bottom: parent.bottom
                    width: 4
                    height: Math.max(2, modelData * 28)
                    radius: 1
                    color: modelData > 0.8 ? Theme.rose : Theme.surface2
                }
            }
        }
    }

    // ── Quick settings ───────────────────────────────────────────────
    SectionLabel { text: "quick settings" }

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: Theme.gap
        rowSpacing: Theme.gap

        QuickToggle {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            icon: Network.ethConnected ? Icons.ethernet : Network.enabled ? Icons.wifi : Icons.wifiOff
            label: "Wi-Fi"
            sublabel: Network.ssid !== "" ? Network.ssid
                    : Network.ethConnected ? "Off · via LAN"
                    : Network.enabled ? "Not connected" : "Off"
            active: Network.enabled
            busy: Network.busy
            onClicked: Network.toggle()
        }
        QuickToggle {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            icon: Bluetooth.powered ? Icons.bluetooth : Icons.bluetoothOff
            label: "Bluetooth"
            sublabel: !Bluetooth.available ? "No adapter"
                    : !Bluetooth.powered ? "Off"
                    : (Bluetooth.device !== "" ? Bluetooth.device : "On")
            active: Bluetooth.powered
            busy: Bluetooth.busy
            enabled: Bluetooth.available
            onClicked: Bluetooth.toggle()
        }
        QuickToggle {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            icon: Icons.night
            label: "Night light"
            sublabel: !NightLight.available ? "hyprsunset missing"
                    : NightLight.active ? NightLight.temperature + "K" : "Off"
            active: NightLight.active
            enabled: NightLight.available
            onClicked: NightLight.toggle()
        }
        QuickToggle {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            icon: Notifications.dnd ? Icons.bellOff : Icons.bell
            label: "Do not disturb"
            sublabel: !Notifications.available ? "No daemon"
                    : (Notifications.dnd ? "On" : "Off")
                      + (Notifications.count > 0 ? "  ·  " + Notifications.count + " baru" : "")
            active: Notifications.dnd
            enabled: Notifications.available
            onClicked: Notifications.toggle()
        }
    }

    // ── Sistem ───────────────────────────────────────────────────────
    SectionLabel { Layout.topMargin: 6; text: "system" }

    InfoRow {
        key: "network"
        value: Network.ethConnected ? "ethernet · " + Network.ethIp
             : Network.ssid !== "" ? "wi-fi · " + Network.wifiIp : "offline"
    }
    InfoRow {
        visible: Battery.available
        key: "battery"
        value: Battery.percent + "% · " + Battery.status.toLowerCase()
    }
    InfoRow { key: "resolution"; value: SystemInfo.resolution }
    InfoRow { key: "compositor"; value: SystemInfo.compositor }
    InfoRow { key: "kernel";     value: SystemInfo.kernel }
    InfoRow { key: "uptime";     value: SystemInfo.uptime }
}
