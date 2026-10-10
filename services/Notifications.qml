pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Notifikasi: swaync (lengkap), mako atau dunst (DND saja).
// swaync dipantau live lewat `swaync-client -s` (JSON per baris):
//   {"count": 3, "dnd": false, "visible": false, "inhibited": false}
// Isi notifikasi tetap ditampilkan oleh panel swaync sendiri; swaync-client
// tidak menyediakan perintah untuk membaca daftar notifikasi.
Singleton {
    id: root

    property string daemon: ""       // "swaync" | "mako" | "dunst" | "none"
    property bool dnd: false
    property int count: 0            // jumlah notifikasi (swaync)
    property bool panelVisible: false
    readonly property bool available: daemon !== "" && daemon !== "none"
    readonly property bool isSwaync: daemon === "swaync"

    function refresh() {
        if (!proc.running) proc.running = true;
    }

    function toggle() {
        if (!available) return;
        dnd = !dnd;
        const cmd = {
            swaync: ["swaync-client", "-d", "-sw"],
            mako: ["makoctl", "mode", "-t", "do-not-disturb"],
            dunst: ["dunstctl", "set-paused", "toggle"]
        }[daemon];
        Quickshell.execDetached(cmd);
    }

    function openPanel() {
        if (isSwaync) Quickshell.execDetached(["swaync-client", "-t", "-sw"]);
    }

    function clearAll() {
        if (isSwaync) { Quickshell.execDetached(["swaync-client", "-C", "-sw"]); count = 0; }
        else if (daemon === "mako") Quickshell.execDetached(["makoctl", "dismiss", "-a"]);
        else if (daemon === "dunst") Quickshell.execDetached(["dunstctl", "close-all"]);
    }

    readonly property string script: [
        'if pidof swaync >/dev/null; then echo swaync; swaync-client -D 2>/dev/null',
        'elif pidof mako >/dev/null; then echo mako; makoctl mode 2>/dev/null | grep -qx do-not-disturb && echo true || echo false',
        'elif pidof dunst >/dev/null; then echo dunst; dunstctl is-paused 2>/dev/null',
        'else echo none; fi'
    ].join("\n")

    Process {
        id: proc
        command: ["sh", "-c", root.script]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.trim().split("\n");
                root.daemon = l[0] ?? "none";
                root.dnd = (l[1] ?? "").trim() === "true";
            }
        }
    }

    // Langganan live swaync; dijalankan ulang kalau terputus (mis. swaync di-restart)
    Process {
        id: subscribe
        command: ["swaync-client", "-s"]
        running: root.isSwaync
        stdout: SplitParser {
            onRead: line => {
                let j;
                try { j = JSON.parse(line); } catch (e) { return; }
                root.count = j.count ?? 0;
                root.dnd = j.dnd ?? root.dnd;
                root.panelVisible = j.visible ?? false;
            }
        }
    }

    Timer {
        interval: 5000
        repeat: true
        running: root.isSwaync && !subscribe.running
        onTriggered: subscribe.running = true
    }

    Component.onCompleted: refresh()
}
