pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Night light via hyprsunset. Nyala = proses hyprsunset berjalan.
// Ganti suhu = restart hyprsunset dengan -t baru (bekerja di semua versi).
Singleton {
    id: root

    property bool available: false
    property bool active: false
    property int temperature: Config.nightLightDefault

    function refresh() {
        if (!proc.running) proc.running = true;
    }

    function start() {
        Quickshell.execDetached(["sh", "-c",
            "pkill -x hyprsunset; sleep 0.2; exec hyprsunset -t " + temperature + " >/dev/null 2>&1"]);
        active = true;
    }

    function stop() {
        Quickshell.execDetached(["pkill", "-x", "hyprsunset"]);
        active = false;
    }

    function toggle() {
        if (!available) return;
        if (active) stop(); else start();
    }

    function setTemperature(t) {
        temperature = t;
        if (active) start();
    }

    Process {
        id: proc
        command: ["sh", "-c",
            "command -v hyprsunset >/dev/null && echo yes || echo no; pidof hyprsunset >/dev/null && echo on || echo off"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.split("\n");
                root.available = l[0] === "yes";
                root.active = l[1] === "on";
            }
        }
    }

    Component.onCompleted: refresh()
}
