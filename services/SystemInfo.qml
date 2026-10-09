pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Info statis/lambat: hostname, uptime, kernel, distro, versi Hyprland, resolusi.
Singleton {
    id: root

    property string user: Quickshell.env("USER") ?? "user"
    property string host: "localhost"
    property string uptime: ""
    property string kernel: ""
    property string os: ""
    property string compositor: ""
    property string resolution: ""

    function refresh() {
        if (!proc.running) proc.running = true;
    }

    function formatUptime(s) {
        const d = Math.floor(s / 86400);
        const h = Math.floor(s % 86400 / 3600);
        const m = Math.floor(s % 3600 / 60);
        return d > 0 ? d + "d " + h + "h" : h + "h " + m + "m";
    }

    // Tiap perintah dibungkus echo "$(...)" agar selalu tepat satu baris.
    Process {
        id: proc
        command: ["sh", "-c", [
            'echo "$(cat /proc/sys/kernel/hostname)"',
            'echo "$(cut -d. -f1 /proc/uptime)"',
            'echo "$(uname -r)"',
            'echo "$(. /etc/os-release 2>/dev/null; echo $PRETTY_NAME)"',
            'echo "$(hyprctl version 2>/dev/null | head -n1 | grep -oE "[0-9]+\\.[0-9]+\\.[0-9]+" | head -n1)"',
            'echo "$(hyprctl monitors 2>/dev/null | grep -m1 -oE "[0-9]+x[0-9]+@[0-9.]+")"'
        ].join("\n")]

        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.split("\n");
                if (l[0]) root.host = l[0];
                root.uptime = l[1] ? root.formatUptime(parseInt(l[1])) : "";
                root.kernel = l[2] ?? "";
                root.os = l[3] ?? "";
                root.compositor = l[4] ? "Hyprland v" + l[4] : "";

                // "2560x1600@165.00000" -> "2560×1600 @ 165Hz"
                const r = (l[5] ?? "").match(/(\d+)x(\d+)@([\d.]+)/);
                root.resolution = r ? r[1] + "×" + r[2] + " @ " + Math.round(parseFloat(r[3])) + "Hz" : "";
            }
        }
    }

    Component.onCompleted: refresh()
}
