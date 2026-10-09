pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Status bar: tampil/sembunyi, layout aktif, dan DAFTAR LAYOUT.
//
// Menambah layout = menambah satu entri di `layouts`:
//   style  : "solid"   satu bar utuh (radius + margin = bar melayang)
//            "islands" bar transparan, kiri/tengah/kanan jadi "pulau" sendiri
//            "border"  transparan, tiap modul hanya bergaris tepi
//   height, radius, margin { top, left, right }, flatTop (hanya sudut bawah membulat)
//   left / center / right : daftar modul, lihat bar/Module.qml
//     workspaces[:kanji|:roman] window clock date datetime launcher network bluetooth
//     volume mic brightness battery cpu memory tray notification profile power control
Singleton {
    id: root

    property bool shown: Config.barEnabled
    property string current: Config.barLayout

    readonly property var layouts: ({
        "omarchy": {
            style: "solid", height: 30, radius: 0, margin: { top: 5, left: 10, right: 10 },
            left:   ["launcher", "workspaces", "window:app"],
            center: ["clock"],
            right:  ["network", "bluetooth", "volume", "cpu", "memory", "battery", "tray", "power", "control"]
        },
        "minimal": {
            style: "solid", height: 30, radius: 0, margin: { top: 0, left: 0, right: 0 },
            left:   ["power", "battery", "clock", "workspaces"],
            center: [],
            right:  ["volume", "network", "tray", "notification", "control"]
        },
        "full": {
            style: "islands", height: 34, radius: 10, margin: { top: 8, left: 10, right: 10 },
            left:   ["clock", "power", "network", "bluetooth", "mic"],
            center: ["workspaces", "profile"],
            right:  ["battery", "volume", "brightness", "control"]
        },
        "cozy": {
            style: "islands", height: 32, radius: 12, margin: { top: 6, left: 10, right: 10 },
            left:   ["clock", "battery", "workspaces:kanji"],
            center: [],
            right:  ["network", "volume", "mic", "notification", "tray", "control"]
        },
        "everforest": {
            style: "solid", height: 26, radius: 15, flatTop: true, margin: { top: 0, left: 120, right: 120 },
            left:   ["launcher", "clock", "date"],
            center: ["workspaces"],
            right:  ["volume", "network", "battery", "power", "control"]
        },
        "border-only": {
            style: "border", height: 40, radius: 2, margin: { top: 0, left: 10, right: 10 },
            left:   ["clock", "network"],
            center: ["workspaces"],
            right:  ["volume", "brightness", "battery", "tray", "control"]
        },
        "hyprnova": {
            style: "solid", height: 30, radius: 8, margin: { top: 3, left: 8, right: 8 },
            left:   ["launcher", "workspaces:roman", "notification", "tray"],
            center: ["clock"],
            right:  ["cpu", "memory", "battery", "brightness", "volume", "mic", "power", "control"]
        }
    })

    readonly property var names: Object.keys(layouts)
    readonly property var layout: layouts[current] ?? layouts[Config.barLayout] ?? layouts[names[0]]
    readonly property var allModules: layout.left.concat(layout.center, layout.right)

    // Jam bersama untuk semua bar
    property alias clock: sysClock
    SystemClock {
        id: sysClock
        precision: SystemClock.Minutes
    }

    function set(name) {
        if (!layouts[name]) return false;
        current = name;
        saveProc.command = ["sh", "-c", 'mkdir -p "$(dirname "$2")" && printf "%s\\n" "$1" > "$2"',
                            "sh", name, Config.barStateFile];
        saveProc.running = true;
        return true;
    }

    function next() {
        const i = names.indexOf(current);
        set(names[(i + 1) % names.length]);
    }

    // Pulihkan layout terakhir saat start
    FileView {
        path: Config.barStateFile
        printErrors: false
        onLoaded: {
            const n = text().trim();
            if (root.layouts[n]) root.current = n;
        }
    }

    Process { id: saveProc }
}
