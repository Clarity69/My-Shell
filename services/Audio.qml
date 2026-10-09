pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Audio via wpctl (PipeWire/WirePlumber): volume & mute speaker dan mic,
// daftar output/input, pilih perangkat default.
Singleton {
    id: root

    readonly property string sink: "@DEFAULT_AUDIO_SINK@"
    readonly property string source: "@DEFAULT_AUDIO_SOURCE@"

    property real volume: 0
    property bool muted: false
    property real micVolume: 0
    property bool micMuted: false
    property bool hasMic: false

    property var sinks: []       // [{ id, name, isDefault }]
    property var sources: []

    // Hanya satu proses wpctl per target; nilai terakhir dikirim setelah proses selesai.
    property real pending: -1
    property real micPending: -1

    function refresh() {
        if (!statusProc.running && !setProc.running && !micProc.running) statusProc.running = true;
    }

    function setVolume(v) {
        volume = Math.max(0, Math.min(1, v));
        pending = volume;
        if (!setProc.running) flush();
    }
    function flush() {
        if (pending < 0) return;
        setProc.command = ["wpctl", "set-volume", "-l", "1.0", sink, pending.toFixed(2)];
        pending = -1;
        setProc.running = true;
    }

    function setMicVolume(v) {
        micVolume = Math.max(0, Math.min(1, v));
        micPending = micVolume;
        if (!micProc.running) flushMic();
    }
    function flushMic() {
        if (micPending < 0) return;
        micProc.command = ["wpctl", "set-volume", "-l", "1.0", source, micPending.toFixed(2)];
        micPending = -1;
        micProc.running = true;
    }

    function toggleMute() {
        muted = !muted;
        Quickshell.execDetached(["wpctl", "set-mute", sink, "toggle"]);
    }
    function toggleMicMute() {
        micMuted = !micMuted;
        Quickshell.execDetached(["wpctl", "set-mute", source, "toggle"]);
    }

    function setDefault(dev, isSink) {
        Quickshell.execDetached(["wpctl", "set-default", String(dev.id)]);
        const mark = list => list.map(d => Object.assign({}, d, { isDefault: d.id === dev.id }));
        if (isSink) sinks = mark(sinks); else sources = mark(sources);
    }

    function parseDevice(line) {
        const clean = line.replace(/[│├└─]/g, " ");
        const m = clean.match(/^\s*(\*)?\s*(\d+)\.\s+(.+?)\s*(\[vol:[^\]]*\])?\s*$/);
        return m ? { id: parseInt(m[2]), name: m[3], isDefault: m[1] === "*" } : null;
    }

    // Baris 1-2: get-volume sink & source; lalu S|… (sink) dan R|… (source) dari `wpctl status`
    readonly property string statusScript: [
        'echo "$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)"',
        'echo "$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null)"',
        'wpctl status 2>/dev/null | awk \'/^[A-Za-z]/ {a = ($1 == "Audio")}',
        '  a && /Sinks:/ {m = "S"; next}',
        '  a && /Sources:/ {m = "R"; next}',
        '  a && /(Devices|Filters|Streams):/ {m = ""; next}',
        '  a && m != "" && /[0-9]+\\./ {print m "|" $0}\''
    ].join("\n")

    Process {
        id: statusProc
        command: ["sh", "-c", root.statusScript]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.split("\n");

                const v = (l[0] ?? "").match(/Volume:\s*([\d.]+)/);
                if (v) root.volume = Math.min(1, parseFloat(v[1]));
                root.muted = (l[0] ?? "").includes("[MUTED]");

                const mv = (l[1] ?? "").match(/Volume:\s*([\d.]+)/);
                root.hasMic = !!mv;
                if (mv) root.micVolume = Math.min(1, parseFloat(mv[1]));
                root.micMuted = (l[1] ?? "").includes("[MUTED]");

                const s = [], r = [];
                for (const line of l.slice(2)) {
                    const d = root.parseDevice(line.slice(2));
                    if (!d) continue;
                    if (line.startsWith("S|")) s.push(d);
                    else if (line.startsWith("R|")) r.push(d);
                }
                root.sinks = s;
                root.sources = r;
            }
        }
    }

    Process { id: setProc; onExited: root.flush() }
    Process { id: micProc; onExited: root.flushMic() }

    Component.onCompleted: refresh()
}
