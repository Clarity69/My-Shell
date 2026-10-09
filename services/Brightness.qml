pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Kecerahan layar via brightnessctl (kelas backlight).
//   status : brightnessctl -m -c backlight  -> "intel_backlight,backlight,4800,50%,9600"
//   set    : brightnessctl -c backlight set 50%
// Di desktop tanpa backlight, `available` = false dan slider disembunyikan.
Singleton {
    id: root

    property bool available: false
    property real value: 0       // 0..1
    property real pending: -1

    // Batas bawah agar layar tidak benar-benar gelap total
    readonly property int minPercent: 1

    function refresh() {
        if (!statusProc.running && !setProc.running) statusProc.running = true;
    }

    function setValue(v) {
        if (!available) return;
        v = Math.max(0, Math.min(1, v));
        value = v;
        pending = v;
        if (!setProc.running) flush();
    }

    function flush() {
        if (pending < 0) return;
        const pct = Math.max(minPercent, Math.round(pending * 100));
        setProc.command = ["brightnessctl", "-q", "-c", "backlight", "set", pct + "%"];
        pending = -1;
        setProc.running = true;
    }

    Process {
        id: statusProc
        command: ["sh", "-c", "command -v brightnessctl >/dev/null && brightnessctl -m -c backlight"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(",");
                const cur = parseInt(f[2]);
                const max = parseInt(f[4]);
                root.available = f.length >= 5 && max > 0;
                if (root.available) root.value = cur / max;
            }
        }
    }

    Process {
        id: setProc
        onExited: root.flush()
    }

    Component.onCompleted: refresh()
}
