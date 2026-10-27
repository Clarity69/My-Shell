pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Night light via hyprsunset. On = the hyprsunset process is running.
// Changing the temperature restarts hyprsunset with a new -t (works on every version).
//
// Schedule: when enabled, night light switches on at `onTime` and off at `offTime`
// (windows across midnight like 19:00 → 06:00 work). It only acts at those moments,
// so toggling by hand in between is respected until the next switch time.
// Settings are saved to ~/.cache/quickshell/nightlight.json.
Singleton {
    id: root

    property bool available: false
    property bool active: false
    property int temperature: Config.nightLightDefault

    // ── Schedule ─────────────────────────────────────────────────────
    property bool scheduled: false
    property int onMinutes: 19 * 60        // minutes after midnight
    property int offMinutes: 6 * 60
    property bool loaded: false
    property bool lastInWindow: false

    readonly property string onTime: fmt(onMinutes)
    readonly property string offTime: fmt(offMinutes)

    function fmt(m) {
        m = ((m % 1440) + 1440) % 1440;
        return String(Math.floor(m / 60)).padStart(2, "0") + ":" + String(m % 60).padStart(2, "0");
    }

    function inWindow() {
        const d = new Date();
        const now = d.getHours() * 60 + d.getMinutes();
        return onMinutes <= offMinutes
            ? now >= onMinutes && now < offMinutes          // same day, e.g. 13:00 → 17:00
            : now >= onMinutes || now < offMinutes;          // across midnight, e.g. 19:00 → 06:00
    }

    // Apply the schedule. force = set the state right now (on enable/start/edit),
    // otherwise only act when the window boundary is crossed.
    function check(force) {
        if (!scheduled || !available) return;
        const w = inWindow();
        if (force || w !== lastInWindow) {
            if (w && !active) start();
            else if (!w && active) stop();
        }
        lastInWindow = w;
    }

    function setScheduled(v) { scheduled = v; save(); check(true); }
    function setOn(m)  { onMinutes = ((m % 1440) + 1440) % 1440; save(); check(true); }
    function setOff(m) { offMinutes = ((m % 1440) + 1440) % 1440; save(); check(true); }

    Timer {
        interval: 30000
        repeat: true
        running: root.scheduled && root.available
        onTriggered: root.check(false)
    }

    // ── Control ──────────────────────────────────────────────────────
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
        save();
        if (active) start();
    }

    Process {
        id: proc
        command: ["sh", "-c",
            "command -v hyprsunset >/dev/null && echo yes || echo no; pidof hyprsunset >/dev/null && echo on || echo off"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.split("\n");
                const wasAvailable = root.available;
                root.available = l[0] === "yes";
                root.active = l[1] === "on";
                if (!wasAvailable && root.available && root.loaded) root.check(true);
            }
        }
    }

    // ── Persistence ──────────────────────────────────────────────────
    readonly property string stateFile: Config.home + "/.cache/quickshell/nightlight.json"

    function save() {
        if (!loaded) return;
        saveProc.command = ["sh", "-c", 'mkdir -p "$(dirname "$2")" && printf "%s\\n" "$1" > "$2"', "sh",
            JSON.stringify({ scheduled: scheduled, on: onMinutes, off: offMinutes, temperature: temperature }),
            stateFile];
        saveProc.running = true;
    }

    Process { id: saveProc }

    FileView {
        path: root.stateFile
        printErrors: false
        onLoaded: {
            try {
                const o = JSON.parse(text());
                root.scheduled = o.scheduled ?? false;
                root.onMinutes = o.on ?? root.onMinutes;
                root.offMinutes = o.off ?? root.offMinutes;
                root.temperature = o.temperature ?? root.temperature;
            } catch (e) {}
            root.loaded = true;
            root.check(true);
        }
        onLoadFailed: { root.loaded = true; }
    }

    Component.onCompleted: refresh()
}
