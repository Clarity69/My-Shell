pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Bluetooth via bluetoothctl: power, perangkat ter-pair, connect/disconnect.
// `timeout` mencegah bluetoothctl menggantung kalau bluetoothd tidak jalan.
Singleton {
    id: root

    property bool available: false
    property bool powered: false
    property string device: ""        // nama perangkat pertama yang terhubung
    property var devices: []          // [{ mac, name, connected }]
    property string pending: ""       // MAC yang sedang di-connect/disconnect
    property bool busy: false

    function refresh() {
        if (!statusProc.running && !busy) statusProc.running = true;
    }

    function toggle() {
        if (busy || !available) return;
        busy = true;
        const target = !powered;
        powered = target;
        if (!target) device = "";
        toggleProc.command = target
            ? ["sh", "-c", "rfkill unblock bluetooth; sleep 0.3; timeout 5 bluetoothctl power on"]
            : ["timeout", "5", "bluetoothctl", "power", "off"];
        toggleProc.running = true;
    }

    function toggleDevice(d) {
        if (devProc.running || !powered) return;
        pending = d.mac;
        devProc.command = ["timeout", "15", "bluetoothctl", d.connected ? "disconnect" : "connect", d.mac];
        devProc.running = true;
    }

    // Baris 1: Powered yes/no (kosong = tanpa adapter), lalu C|MAC Nama dan P|MAC Nama
    readonly property string statusScript: [
        'echo "$(timeout 3 bluetoothctl show 2>/dev/null | awk \'/Powered:/ {print $2; exit}\')"',
        'timeout 3 bluetoothctl devices Connected 2>/dev/null | sed -n "s/^Device /C|/p"',
        '{ timeout 3 bluetoothctl devices Paired 2>/dev/null || timeout 3 bluetoothctl paired-devices 2>/dev/null; } | sed -n "s/^Device /P|/p"'
    ].join("\n")

    Process {
        id: statusProc
        command: ["sh", "-c", root.statusScript]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                const state = (lines[0] ?? "").trim();
                root.available = state === "yes" || state === "no";
                root.powered = state === "yes";

                const map = {};
                const connected = {};
                for (const l of lines) {
                    if (!l.startsWith("C|") && !l.startsWith("P|")) continue;
                    const rest = l.slice(2);
                    const mac = rest.split(" ")[0];
                    const name = rest.slice(mac.length + 1) || mac;
                    if (l.startsWith("C|")) connected[mac] = true;
                    map[mac] = { mac: mac, name: name, connected: false };
                }
                for (const mac in connected) if (map[mac]) map[mac].connected = true;

                root.devices = Object.values(map).sort((a, b) =>
                    (b.connected - a.connected) || a.name.localeCompare(b.name));
                const first = root.devices.find(d => d.connected);
                root.device = root.powered && first ? first.name : "";
            }
        }
    }

    Process {
        id: toggleProc
        onExited: (code, status) => {
            root.busy = false;
            root.refresh();
        }
    }

    Process {
        id: devProc
        onExited: (code, status) => {
            root.pending = "";
            root.refresh();
        }
    }

    Component.onCompleted: refresh()
}
