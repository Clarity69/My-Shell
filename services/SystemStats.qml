pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Telemetri live dari /proc dan /sys, tanpa dependensi tambahan.
//   cpu  : selisih /proc/stat antar polling
//   mem  : MemTotal - MemAvailable
//   temp : hwmon coretemp/k10temp/zenpower, fallback thermal_zone0
//   net  : total rx/tx semua interface kecuali lo, dibagi waktu
Singleton {
    id: root

    property real cpu: 0          // 0..1
    property int temp: 0          // °C, 0 = tidak terbaca
    property real memUsed: 0      // KiB
    property real memTotal: 0     // KiB
    readonly property real mem: memTotal > 0 ? memUsed / memTotal : 0
    property real rxRate: 0       // byte/detik
    property real txRate: 0
    property var history: []      // riwayat cpu (maks 48 titik)

    property var prevCpu: null
    property var prevNet: null

    function refresh() {
        if (!proc.running) proc.running = true;
    }

    function formatRate(b) {
        if (b >= 1048576) return { v: (b / 1048576).toFixed(1), u: "MB/s" };
        if (b >= 1024)    return { v: (b / 1024).toFixed(0),    u: "KB/s" };
        return { v: Math.round(b).toString(), u: "B/s" };
    }

    function formatKiB(k) {
        return (k / 1048576).toFixed(1) + "G";
    }

    function parse(text) {
        const l = text.trim().split("\n");
        if (l.length < 4) return;

        // CPU
        const c = l[0].trim().split(/\s+/).map(Number);
        const idle = c[3] + c[4];
        const total = c.reduce((a, b) => a + b, 0);
        if (prevCpu && total > prevCpu.total)
            cpu = 1 - (idle - prevCpu.idle) / (total - prevCpu.total);
        prevCpu = { idle: idle, total: total };

        // Memori
        const m = l[1].trim().split(/\s+/).map(Number);
        memTotal = m[0];
        memUsed = m[0] - m[1];

        // Suhu
        temp = Math.round(Number(l[2]) / 1000);

        // Jaringan
        const n = l[3].trim().split(/\s+/).map(Number);
        const now = Date.now();
        if (prevNet) {
            const s = (now - prevNet.t) / 1000;
            if (s > 0) {
                rxRate = Math.max(0, (n[0] - prevNet.rx) / s);
                txRate = Math.max(0, (n[1] - prevNet.tx) / s);
            }
        }
        prevNet = { rx: n[0], tx: n[1], t: now };

        const h = history.slice(-47);
        h.push(cpu);
        history = h;
    }

    Process {
        id: proc
        command: ["sh", "-c", [
            "awk '/^cpu /{print $2,$3,$4,$5,$6,$7,$8,$9; exit}' /proc/stat",
            "awk '/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2} END{print t, a}' /proc/meminfo",
            "t=0; for h in /sys/class/hwmon/hwmon*; do " +
                "case \"$(cat $h/name 2>/dev/null)\" in " +
                "coretemp|k10temp|zenpower|cpu_thermal) t=$(cat $h/temp1_input 2>/dev/null); break;; esac; done; " +
                "[ \"$t\" = 0 ] && t=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0); echo $t",
            "sed 1,2d /proc/net/dev | sed 's/:/ /' | awk '$1!=\"lo\"{rx+=$2; tx+=$10} END{print rx+0, tx+0}'"
        ].join("\n")]

        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }
}
