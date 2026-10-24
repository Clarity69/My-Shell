pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Opsi tampilan Hyprland. Diterapkan langsung lewat `hyprctl eval` (config Lua),
// lalu disimpan ke Config.hyprOverrides (quickshell.lua) agar bertahan setelah
// reload/login. File itu dimuat lewat load("quickshell") di akhir hyprland.lua.
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

    // Nilai JS -> literal Lua
    function luaValue(value) {
        if (typeof value === "boolean") return value ? "true" : "false";
        return String(value);
    }

    // "decoration:blur:enabled", true -> hl.config({ decoration = { blur = { enabled = true } } })
    function luaSet(path, value) {
        const parts = path.split(":");
        let s = luaValue(value);
        for (let i = parts.length - 1; i >= 0; i--)
            s = "{ " + parts[i] + " = " + s + " }";
        return "hl.config(" + s + ")";
    }

    function set(key, value) {
        root[key] = value;
        Quickshell.execDetached(["hyprctl", "eval", luaSet(options[key], value)]);
        saveTimer.restart();
    }

    function readValue(j) {
        if (j.bool !== undefined) return j.bool ? 1 : 0;
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
                "-- Ditulis otomatis oleh Quickshell Control Center.",
                "hl.config({",
                "    general = {",
                "        gaps_in = " + root.gapsIn + ",",
                "        gaps_out = " + root.gapsOut + ",",
                "        border_size = " + root.borderSize + ",",
                "    },",
                "    decoration = {",
                "        rounding = " + root.rounding + ",",
                "        blur = { enabled = " + root.luaValue(root.blur) + " },",
                "    },",
                "    animations = { enabled = " + root.luaValue(root.animations) + " },",
                "})"
            ].join("\n");
            writeProc.command = ["sh", "-c",
                'mkdir -p "$(dirname "$2")" && printf "%s\\n" "$1" > "$2"', "sh", content, Config.hyprOverrides];
            writeProc.running = true;
        }
    }

    Process { id: writeProc }
}
