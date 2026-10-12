pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Kalender kontribusi GitHub. bin/github-contrib menulis cache, service ini membaca cache.
// Cache langsung dipakai saat start (tetap tampil walau offline), lalu diperbarui berkala.
Singleton {
    id: root

    readonly property bool shown: WidgetSettings.githubShown   // diatur di halaman Widgets
    property string user: ""
    property int total: 0
    property var days: []            // [{ date: Date, iso, count, level }] urut kronologis
    property bool loading: false
    property string error: ""
    property date updated

    // Statistik turunan
    readonly property int currentStreak: {
        let s = 0;
        for (let i = days.length - 1; i >= 0; i--) {
            if (days[i].count > 0) s++;
            else if (i === days.length - 1) continue;   // hari ini belum commit: jangan putus dulu
            else break;
        }
        return s;
    }
    readonly property int longestStreak: {
        let best = 0, cur = 0;
        for (const d of days) { cur = d.count > 0 ? cur + 1 : 0; best = Math.max(best, cur); }
        return best;
    }
    readonly property var bestDay: days.reduce((a, d) => (!a || d.count > a.count) ? d : a, null)

    function refresh() {
        if (proc.running) return;
        loading = true;
        error = "";
        proc.running = true;
    }

    function parse(raw) {
        const out = [];
        let u = "", t = 0;
        for (const line of raw.split("\n")) {
            const p = line.split("|");
            if (p[0] === "U") u = p[1];
            else if (p[0] === "T") t = parseInt(p[1]) || 0;
            else if (p[0] === "D" && p.length >= 4) {
                const [y, m, d] = p[1].split("-").map(Number);
                out.push({ date: new Date(y, m - 1, d), iso: p[1],
                           count: parseInt(p[2]) || 0, level: Math.max(0, Math.min(4, parseInt(p[3]) || 0)) });
            }
        }
        if (out.length === 0) return;
        out.sort((a, b) => a.date - b.date);
        user = u;
        total = t || out.reduce((s, d) => s + d.count, 0);
        days = out;
    }

    FileView {
        id: cache
        path: Config.githubCache
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            root.parse(text());
            root.updated = new Date();
        }
    }

    Process {
        id: proc
        command: [Config.githubScript, Config.githubUser, Config.githubCache]
        stderr: StdioCollector {
            onStreamFinished: if (text.trim() !== "") root.error = text.trim().split("\n").pop()
        }
        onExited: (code, status) => { root.loading = false; }
    }

    Timer {
        interval: Math.max(5, Config.githubRefreshMinutes) * 60 * 1000
        repeat: true
        running: root.shown
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
