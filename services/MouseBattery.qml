pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Battery of the 2.4 GHz mouse on the YJX-CHIP receiver (a8a5:2255), read by bin/mouse-battery.
// The receiver only answers while the mouse is awake, so an idle mouse keeps its last level
// (`asleep` = true) instead of disappearing. Warns once when the level drops below
// Config.mouseLowBattery while not charging.
Singleton {
    id: root

    property bool available: false      // answered at least once
    property bool asleep: false         // last poll got no answer
    property int level: 0
    property bool charging: false
    property date updated: new Date(0)
    property bool warned: false

    function refresh() {
        if (!proc.running) proc.running = true;
    }

    // Prints "<exit code> <level> <charging>" so one stream carries everything
    Process {
        id: proc
        command: ["sh", "-c", 'out=$("$1" 2>/dev/null); echo "$? $out"', "sh", Config.mouseBatteryScript]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split(/\s+/);
                const code = parseInt(p[0]);
                if (code === 0 && p.length >= 3) {
                    root.level = parseInt(p[1]);
                    root.charging = p[2] === "1";
                    root.available = true;
                    root.asleep = false;
                    root.updated = new Date();
                    root.checkLow();
                } else if (code === 1 || code === 127) {
                    root.available = false;        // receiver unplugged / script missing
                } else {
                    root.asleep = true;            // asleep, busy or no permission: keep the last level
                }
            }
        }
    }

    function checkLow() {
        if (charging || level > Config.mouseLowBattery) { warned = false; return; }
        if (warned) return;
        warned = true;
        Quickshell.execDetached(["notify-send", "-a", "Mouse", "-u", "critical", "-i", "input-mouse",
                                 "Mouse battery low", level + "% left — time to charge"]);
    }

    Timer {
        interval: Math.max(15, Config.mouseBatteryInterval) * 1000
        repeat: true
        running: Config.mouseBattery
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
