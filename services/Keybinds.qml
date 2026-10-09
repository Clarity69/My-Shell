pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Daftar keybind aktif dari `hyprctl binds -j`.
Singleton {
    id: root

    property var binds: []    // [{ keys: ["SUPER", "A"], desc, submap }]

    function refresh() {
        if (!proc.running) proc.running = true;
    }

    function mods(mask) {
        const out = [];
        if (mask & 64) out.push("SUPER");
        if (mask & 4)  out.push("CTRL");
        if (mask & 8)  out.push("ALT");
        if (mask & 1)  out.push("SHIFT");
        return out;
    }

    function prettyKey(k) {
        const mouse = { "mouse:272": "LMB", "mouse:273": "RMB", "mouse:274": "MMB",
                        "mouse_up": "WHEEL ↑", "mouse_down": "WHEEL ↓" };
        if (mouse[k]) return mouse[k];
        return k.length === 1 ? k.toUpperCase() : k;
    }

    Process {
        id: proc
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                let list;
                try { list = JSON.parse(text); } catch (e) { return; }
                root.binds = list.map(b => ({
                    keys: root.mods(b.modmask).concat(b.key ? [root.prettyKey(b.key)] : []),
                    desc: b.description || ((b.dispatcher ?? "") + " " + (b.arg ?? "")).trim(),
                    submap: b.submap ?? ""
                }));
            }
        }
    }
}
