pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Baterai dari /sys/class/power_supply/BAT*; sisa waktu dari upower (opsional).
Singleton {
    id: root

    property bool available: false
    property int percent: 0
    property string status: ""       // Charging | Discharging | Full | Not charging
    property string timeLeft: ""
    property real watts: 0

    readonly property bool charging: status === "Charging"

    function refresh() {
        if (!proc.running) proc.running = true;
    }

    readonly property string script: [
        'b=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -n1)',
        '[ -z "$b" ] && { echo none; exit 0; }',
        'echo "$(cat "$b/capacity" 2>/dev/null)"',
        'echo "$(cat "$b/status" 2>/dev/null)"',
        'echo "$(cat "$b/power_now" 2>/dev/null)"',
        'echo "$(upower -i "$(upower -e 2>/dev/null | grep -m1 BAT)" 2>/dev/null | awk -F": *" \'/time to (empty|full)/ {print $2; exit}\')"'
    ].join("\n")

    Process {
        id: proc
        command: ["sh", "-c", root.script]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.split("\n");
                root.available = l[0] !== "none" && l[0] !== "";
                if (!root.available) return;
                root.percent = parseInt(l[0]) || 0;
                root.status = l[1] ?? "";
                root.watts = (parseInt(l[2]) || 0) / 1e6;
                root.timeLeft = l[3] ?? "";
            }
        }
    }

    Component.onCompleted: refresh()
}
