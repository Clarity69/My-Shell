pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.config

// External display (TV / projector) handling through hyprctl.
//   mode "extend"  TV is a second screen to the right of the laptop
//   mode "mirror"  TV shows the same picture as the laptop
//   mode "off"     laptop only, the TV is switched off
// `resolution` is the mode used for the TV ("preferred" or e.g. "1920x1080@60").
// Changes are runtime only (hyprctl keyword), so unplugging or restarting Hyprland
// falls back to whatever monitors.conf says.
Singleton {
    id: root

    property var monitors: []          // [{ name, desc, width, height, refresh, mirrorOf, disabled, modes }]
    property bool busy: false
    property string resolution: Config.externalMode

    // Laptop panel = eDP / LVDS / DSI; anything else is external
    readonly property var internal: monitors.find(m => /^(eDP|LVDS|DSI)/.test(m.name)) ?? monitors[0] ?? null
    readonly property var external: monitors.find(m => m !== internal) ?? null
    readonly property bool connected: external !== null
    readonly property bool mirroring: connected && external.mirrorOf !== "" && external.mirrorOf !== "none"
    readonly property string mode: !connected ? "none" : external.disabled ? "off" : mirroring ? "mirror" : "extend"

    // Resolutions the TV offers (deduplicated, highest first), e.g. ["1920x1080@60", "1360x768@60"]
    readonly property var resolutions: {
        if (!connected) return [];
        const seen = {};
        return external.modes.filter(r => !seen[r] && (seen[r] = true));
    }

    function refresh() {
        if (!listProc.running) listProc.running = true;
    }

    function setMode(m) {
        if (!connected || !internal || busy) return;
        const ext = external.name;
        const rule = m === "off" ? ext + ",disable"
            : m === "mirror" ? ext + "," + resolution + ",auto,1,mirror," + internal.name
            : ext + "," + resolution + ",auto,1";
        busy = true;
        setProc.command = ["hyprctl", "keyword", "monitor", rule];
        setProc.running = true;
    }

    function toggleMirror() { setMode(mirroring ? "extend" : "mirror"); }

    // Change the TV resolution and re-apply the current mode with it
    function setResolution(r) {
        resolution = r;
        if (mode === "extend" || mode === "mirror") setMode(mode);
    }

    Process {
        id: listProc
        command: ["hyprctl", "monitors", "all", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.monitors = JSON.parse(text).map(m => ({
                        name: m.name,
                        desc: (m.make ? m.make + " " : "") + (m.model ?? ""),
                        width: m.width,
                        height: m.height,
                        refresh: Math.round(m.refreshRate ?? 0),
                        mirrorOf: m.mirrorOf ?? "",
                        disabled: m.disabled ?? false,
                        modes: (m.availableModes ?? []).map(x => x.replace(/Hz$/, ""))
                    }));
                } catch (e) {}
            }
        }
    }

    Process {
        id: setProc
        onExited: {
            root.busy = false;
            settle.restart();
            wallTimer.restart();      // switching mirror -> extend creates a fresh output without wallpaper
        }
    }

    // Hyprland needs a moment to reconfigure outputs before the new state is readable
    Timer { id: settle; interval: 600; onTriggered: root.refresh() }

    // Plug / unplug / reconfigure events
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name.startsWith("monitor") || event.name === "configreloaded") settle.restart();
            if (event.name === "monitoradded" || event.name === "monitoraddedv2" || event.name === "configreloaded") wallTimer.restart();
        }
    }

    // Re-apply the current wallpaper after outputs change. Screens awww never picks up
    // (seen with a VGA TV) get their wallpaper from desktop/Backdrop.qml instead.
    Timer {
        id: wallTimer
        interval: 1500
        onTriggered: Quickshell.execDetached(["sh", "-c", root.wallScript, "sh",
                                              root.monitors.map(m => m.name).join(" ")])
    }

    readonly property string wallScript: [
        'command -v awww >/dev/null && t=awww d=awww-daemon || { t=swww; d=swww-daemon; }',
        'cache="$HOME/.cache/quickshell/last-wallpaper"',
        'img=$("$t" query 2>/dev/null | grep -m1 -oE "image: .*" | sed "s/^image: //")',
        '[ -n "$img" ] && printf "%s" "$img" > "$cache" || img=$(cat "$cache" 2>/dev/null)',
        '[ -z "$img" ] && exit 0',
        '"$t" img "$img" --transition-type none'
    ].join("\n")

    Component.onCompleted: refresh()
}
