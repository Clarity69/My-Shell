pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Do Not Disturb untuk daemon notifikasi yang sedang berjalan: swaync, mako, atau dunst.
Singleton {
    id: root

    property string daemon: ""       // "swaync" | "mako" | "dunst" | "none"
    property bool dnd: false
    readonly property bool available: daemon !== "" && daemon !== "none"

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

    Component.onCompleted: refresh()
}
