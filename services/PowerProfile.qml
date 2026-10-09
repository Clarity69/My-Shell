pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Mode daya via powerprofilesctl (power-profiles-daemon atau tuned-ppd).
Singleton {
    id: root

    property bool available: false
    property string current: ""
    property var profiles: []        // mis. ["performance", "balanced", "power-saver"]

    function refresh() {
        if (!proc.running) proc.running = true;
    }

    function set(p) {
        current = p;
        Quickshell.execDetached(["powerprofilesctl", "set", p]);
    }

    function pretty(p) {
        return { "power-saver": "Power saver", "balanced": "Balanced", "performance": "Performance" }[p] ?? p;
    }

    readonly property string script: [
        'command -v powerprofilesctl >/dev/null || { echo none; exit 0; }',
        'powerprofilesctl get',
        'powerprofilesctl list | awk \'/^[ *]*[a-z-]+:$/ {gsub(/[ *:]/, ""); print}\''
    ].join("\n")

    Process {
        id: proc
        command: ["sh", "-c", root.script]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.trim().split("\n");
                root.available = l[0] !== "none" && l[0] !== "";
                if (!root.available) return;
                root.current = l[0];
                root.profiles = l.slice(1).filter(p => p !== "");
            }
        }
    }

    Component.onCompleted: refresh()
}
