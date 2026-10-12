pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.config

// Data untuk workspace overview: window & monitor dari hyprctl, diambil saat overview dibuka.
Singleton {
    id: root

    property bool shown: false
    property var clients: []        // [{ address, ws, x, y, w, h, cls, title, floating, monitor }]
    property var monitors: ({})     // name -> { x, y, w, h, activeWs }
    property bool loaded: false

    function toggle() { shown ? close() : open(); }
    function open()   { refresh(); shown = true; }
    function close()  { shown = false; }

    function refresh() {
        if (!proc.running) proc.running = true;
    }

    // "0x55d1a2b3c4d5" dan "55d1a2b3c4d5" dianggap sama
    function normAddr(a) { return String(a ?? "").toLowerCase().replace(/^0x/, ""); }

    function windowsOn(ws) { return clients.filter(c => c.ws === ws); }

    function focusWindow(c) {
        Hyprland.dispatch("focuswindow address:0x" + normAddr(c.address));
        close();
    }

    function goTo(ws) {
        Hyprland.dispatch("workspace " + ws);
        close();
    }

    function moveWindow(c, ws) {
        if (c.ws === ws) return;
        Hyprland.dispatch("movetoworkspacesilent " + ws + ",address:0x" + normAddr(c.address));
        // Update lokal supaya UI langsung berubah, lalu sinkronkan
        clients = clients.map(x => x.address === c.address ? Object.assign({}, x, { ws: ws }) : x);
        refreshLater.restart();
    }

    function closeWindow(c) {
        Hyprland.dispatch("closewindow address:0x" + normAddr(c.address));
        clients = clients.filter(x => x.address !== c.address);
        refreshLater.restart();
    }

    // Toplevel Wayland untuk preview (ScreencopyView). null kalau tidak ketemu.
    function toplevelFor(address) {
        const a = normAddr(address);
        const list = Hyprland.toplevels?.values ?? [];
        for (const t of list)
            if (normAddr(t.address) === a) return t.wayland ?? null;
        return null;
    }

    Timer { id: refreshLater; interval: 300; onTriggered: root.refresh() }

    Process {
        id: proc
        command: ["sh", "-c", "hyprctl -j clients; echo '\n@@SPLIT@@'; hyprctl -j monitors"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.split("@@SPLIT@@");
                let cl = [], mo = [];
                try { cl = JSON.parse(parts[0]); mo = JSON.parse(parts[1]); } catch (e) { return; }

                const mons = {};
                for (const m of mo) {
                    // ukuran logis (setelah scale & rotasi)
                    const rot = (m.transform ?? 0) % 2 === 1;
                    const pw = rot ? m.height : m.width, ph = rot ? m.width : m.height;
                    mons[m.name] = {
                        x: m.x, y: m.y,
                        w: pw / (m.scale || 1), h: ph / (m.scale || 1),
                        activeWs: m.activeWorkspace?.id ?? -1
                    };
                }

                const idToMon = {};
                for (const m of mo) idToMon[m.id] = m.name;

                root.monitors = mons;
                root.clients = cl
                    .filter(c => c.mapped !== false && (c.workspace?.id ?? -1) > 0)
                    .map(c => ({
                        address: c.address,
                        ws: c.workspace.id,
                        x: c.at[0], y: c.at[1], w: c.size[0], h: c.size[1],
                        cls: c.class || c.initialClass || "",
                        title: c.title || "",
                        floating: c.floating === true,
                        monitor: idToMon[c.monitor] ?? ""
                    }));
                root.loaded = true;
            }
        }
    }

    // Data ikut diperbarui saat Hyprland mengirim event selama overview terbuka
    Connections {
        target: Hyprland
        enabled: root.shown
        function onRawEvent(event) {
            if (["openwindow", "closewindow", "movewindow", "movewindowv2", "workspace", "focusedmon"]
                    .includes(event.name))
                refreshLater.restart();
        }
    }
}
