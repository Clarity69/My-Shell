// Ethernet + Wi-Fi (nmcli): status, daftar jaringan, connect/disconnect.

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.services

Page {
    id: root

    property string expanded: ""     // SSID yang sedang dibuka panel aksinya

    onOpened: { Network.refresh(); Network.scan(false); }
    onPoll: Network.refresh()

    // Scan ulang berkala selama halaman terbuka
    Timer {
        interval: 15000
        repeat: true
        running: root.active && Network.enabled
        onTriggered: Network.scan(false)
    }

    PageHeader { kicker: "02 · devices"; title: "Network" }

    // ── Ethernet ─────────────────────────────────────────────────────
    SectionLabel { text: "ethernet" }

    ListRow {
        interactive: false
        active: Network.ethConnected
        icon: Icons.ethernet
        title: Network.ethDevice === "" ? "No ethernet adapter"
             : Network.ethConnected ? "Wired · connected" : "Cable unplugged"
        sub: Network.ethDevice === "" ? ""
           : Network.ethDevice + (Network.ethIp !== "" ? "  ·  " + Network.ethIp : "")
        trailing: Network.ethConnected ? Network.ethSpeed : ""
    }

    // ── Wi-Fi ────────────────────────────────────────────────────────
    SectionLabel { Layout.topMargin: 6; text: "wi-fi" }

    SettingRow {
        icon: Network.enabled ? Icons.wifi : Icons.wifiOff
        title: "Wi-Fi"
        sub: !Network.enabled ? (Network.ethConnected ? "Off — online via LAN" : "Off")
           : Network.ssid !== "" ? Network.ssid + "  ·  " + Network.wifiIp : "Not connected"

        IconButton {
            id: refreshBtn
            visible: Network.enabled
            icon: Icons.refresh
            size: 28
            iconColor: Network.scanning ? Theme.muted : Theme.subtext
            onClicked: Network.scan(true)
            RotationAnimation on rotation {
                running: Network.scanning
                loops: Animation.Infinite
                from: 0; to: 360; duration: 900
                onRunningChanged: if (!running) refreshBtn.rotation = 0
            }
        }
        Switch {
            checked: Network.enabled
            enabled: !Network.busy
            onToggled: Network.toggle()
        }
    }

    Hint {
        visible: Network.error !== ""
        warn: true
        text: Network.error
    }

    Hint {
        visible: Network.enabled && Network.networks.length === 0
        text: Network.scanning ? "Mencari jaringan…" : "Tidak ada jaringan ditemukan."
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2
        visible: Network.enabled

        Repeater {
            model: Network.networks

            ListRow {
                id: row
                required property var modelData
                readonly property bool open: root.expanded === modelData.ssid
                readonly property bool needsPassword: modelData.secure && !modelData.known && !modelData.active

                icon: Icons.wifiStrength[Math.min(4, Math.floor(modelData.signal / 20))]
                title: modelData.ssid
                sub: modelData.security + (modelData.known ? "  ·  saved" : "")
                trailing: Network.connecting === modelData.ssid ? "connecting…"
                        : modelData.active ? "connected" : modelData.signal + "%"
                active: modelData.active
                busy: Network.connecting === modelData.ssid
                onClicked: root.expanded = open ? "" : modelData.ssid

                // Panel aksi saat baris dibuka
                RowLayout {
                    visible: row.open
                    Layout.fillWidth: true
                    spacing: 8

                    InputField {
                        id: pw
                        visible: row.needsPassword
                        password: true
                        placeholder: "Password"
                        onAccepted: if (text !== "") { Network.connect(row.modelData, text); text = ""; }
                    }
                    Item { visible: !row.needsPassword; Layout.fillWidth: true }

                    TextButton {
                        visible: row.modelData.active
                        text: "Disconnect"
                        onClicked: { Network.disconnect(); root.expanded = ""; }
                    }
                    TextButton {
                        visible: !row.modelData.active
                        primary: true
                        text: "Connect"
                        enabled: Network.connecting === "" && (!row.needsPassword || pw.text !== "")
                        onClicked: {
                            Network.connect(row.modelData, pw.text);
                            pw.text = "";
                        }
                    }
                }
            }
        }
    }
}
