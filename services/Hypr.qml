pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Opsi tampilan Hyprland. Diterapkan langsung lewat `hyprctl keyword`,
// lalu disimpan ke Config.hyprOverrides agar bertahan setelah reload/login
// (asalkan file itu di-`source` dari hyprland.conf).
Singleton {
    id: root

    property bool ready: false
    property int gapsIn: 0
    property int gapsOut: 0
    property int borderSize: 0
    property int rounding: 0
    property bool blur: false
    property bool animations: true

    readonly property var options: ({
        gapsIn: "general:gaps_in",
        gapsOut: "general:gaps_out",
        borderSize: "general:border_size",
        rounding: "decoration:rounding",
        blur: "decoration:blur:enabled",
        animations: "animations:enabled"
    })

    function refresh() {
        if (!readProc.running) readProc.running = true;
    }

    function set(key, value) {
        root[key] = value;
        const v = typeof value === "boolean" ? (value ? "1" : "0") : String(value);
        Quickshell.execDetached(["hyprctl", "keyword", options[key], v]);
        saveTimer.restart();
    }

    function readValue(j) {
        if (j.int !== undefined) return j.int;
        if (j.float !== undefined) return Math.round(j.float);
        return parseInt(String(j.custom ?? "0").trim().split(/\s+/)[0]) || 0;
    }

    Process {
        id: readProc
        command: ["sh", "-c",
            "for o in general:gaps_in general:gaps_out general:border_size decoration:rounding " +
            "decoration:blur:enabled animations:enabled; do " +
            "echo \"$(hyprctl -j getoption \"$o\" 2>/dev/null | tr -d '\\n')\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.split("\n");
                const keys = ["gapsIn", "gapsOut", "borderSize", "rounding", "blur", "animations"];
                let ok = 0;
                keys.forEach((k, i) => {
                    try {
                        const v = root.readValue(JSON.parse(l[i]));
                        root[k] = (k === "blur" || k === "animations") ? v !== 0 : v;
                        ok++;
                    } catch (e) {}
                });
                root.ready = ok > 0;
            }
        }
    }

    // Tulis file override 600 ms setelah perubahan terakhir
    Timer {
        id: saveTimer
        interval: 600
        onTriggered: {
            const content = [
                "# Ditulis otomatis oleh Quickshell Control Center.",
                "general {",
                "    gaps_in = " + root.gapsIn,
                "    gaps_out = " + root.gapsOut,
                "    border_size = " + root.borderSize,
                "}",
                "decoration {",
                "    rounding = " + root.rounding,
                "    blur {",
                "        enabled = " + root.blur,
                "    }",
                "}",
                "animations {",
                "    enabled = " + root.animations,
                "}"
            ].join("\n");
            writeProc.command = ["sh", "-c",
                'mkdir -p "$(dirname "$2")" && printf "%s\\n" "$1" > "$2"', "sh", content, Config.hyprOverrides];
            writeProc.running = true;
        }
    }

    Process { id: writeProc }
}
