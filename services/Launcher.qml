pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config

// Logic for the app launcher (launcher/Launcher.qml).
//
//   firefox        apps, fuzzy matched on name / generic name / keywords
//   = 12*7         calculator (also triggers on plain math like 2^10)
//   wifi, sound    jump to a Control Center page
//   lock, reboot   session actions (dangerous ones ask for a second Enter)
//   :clip text     search clipboard history
//   :wall name     pick a wallpaper
//   > command      run a shell command
//   ? query        web search
//
// Modes (Tab / Shift+Tab or click the tabs):
//   apps     everything above
//   run      type a command; recent commands are remembered
//   files    search your home folder (fd if installed, else find), Enter opens it
//   window   switch to an open window
//
// App launches are counted, so the apps you open most float to the top.
Singleton {
    id: root

    property bool open: false
    function toggle() { open = !open; }
    onOpenChanged: if (open) mode = "apps"

    // ── Modes ────────────────────────────────────────────────────────
    readonly property var modes: ["apps", "run", "files", "window"]
    property string mode: "apps"
    function cycleMode(d) {
        const i = modes.indexOf(mode);
        mode = modes[(i + d + modes.length) % modes.length];
    }

    // ── Launch history (frecency) ────────────────────────────────────
    property var history: ({})           // appId -> { n: launches, t: last launch (ms) }

    function frecency(id) {
        const h = history[id];
        if (!h) return 0;
        const days = (Date.now() - h.t) / 86400000;
        const recency = days < 1 ? 4 : days < 7 ? 2 : days < 30 ? 1 : 0.5;
        return h.n * recency;
    }

    function remember(id) {
        const h = Object.assign({}, history);
        h[id] = { n: (h[id]?.n ?? 0) + 1, t: Date.now() };
        history = h;
        saveProc.command = ["sh", "-c", 'mkdir -p "$(dirname "$2")" && printf "%s\\n" "$1" > "$2"',
                            "sh", JSON.stringify(h), Config.launcherHistory];
        saveProc.running = true;
    }

    function rememberRun(cmd) {
        const h = Object.assign({}, history);
        h.__runs = [cmd].concat((h.__runs ?? []).filter(c => c !== cmd)).slice(0, 30);
        history = h;
        saveProc.command = ["sh", "-c", 'mkdir -p "$(dirname "$2")" && printf "%s\\n" "$1" > "$2"',
                            "sh", JSON.stringify(h), Config.launcherHistory];
        saveProc.running = true;
    }

    Process { id: saveProc }

    // ── File search (async) ──────────────────────────────────────────
    property var files: []
    property string fileQuery: ""

    function findFiles(q) {
        fileQuery = q.trim();
        if (fileQuery.length < 2) { files = []; return; }
        fileTimer.restart();
    }

    Timer {
        id: fileTimer
        interval: 180
        onTriggered: {
            if (fileProc.running) fileProc.running = false;
            fileProc.command = ["sh", "-c",
                'cd "$HOME" && if command -v fd >/dev/null; then fd -i -H --max-results 60 --exclude .git --exclude .cache -- "$1"; '
                + 'else find . -maxdepth 5 -not -path "*/.*" -iname "*$1*" 2>/dev/null | head -n 60 | sed "s|^\\./||"; fi',
                "sh", root.fileQuery];
            fileProc.running = true;
        }
    }

    Process {
        id: fileProc
        stdout: StdioCollector {
            onStreamFinished: root.files = text.split("\n").filter(l => l !== "")
        }
    }

    function iconFor(appId) {
        const e = DesktopEntries.heuristicLookup ? DesktopEntries.heuristicLookup(appId) : DesktopEntries.byId(appId);
        return Quickshell.iconPath(e?.icon ?? appId, true);
    }

    FileView {
        path: Config.launcherHistory
        printErrors: false
        onLoaded: { try { root.history = JSON.parse(text()); } catch (e) {} }
    }

    // ── Fuzzy scoring ────────────────────────────────────────────────
    // 0 = no match. Higher is better: exact > prefix > word start > substring > in-order letters.
    function score(hay, q) {
        if (!hay) return 0;
        hay = hay.toLowerCase();
        if (hay === q) return 100;
        if (hay.startsWith(q)) return 80 - Math.min(20, hay.length - q.length) * 0.5;
        const words = hay.split(/[\s\-_.]+/);
        if (words.some(w => w.startsWith(q))) return 60;
        if (words.length > 1 && words.map(w => w[0]).join("").startsWith(q)) return 55;   // "vsc" -> Visual Studio Code
        const idx = hay.indexOf(q);
        if (idx >= 0) return 45 - Math.min(15, idx);
        // letters in order, rewarding consecutive runs
        let i = 0, run = 0, best = 0;
        for (const ch of hay) {
            if (ch === q[i]) { i++; run++; best = Math.max(best, run); if (i === q.length) break; }
            else run = 0;
        }
        return i === q.length ? 10 + best * 3 : 0;
    }

    // ── Static items ─────────────────────────────────────────────────
    readonly property var pages: [
        { name: "Profile", keys: "overview system dossier stats" },
        { name: "Network", keys: "wifi wi-fi ethernet lan internet" },
        { name: "Bluetooth", keys: "headset earbuds pair" },
        { name: "Sound", keys: "audio volume speaker mic microphone" },
        { name: "Display", keys: "brightness night light screen monitor" },
        { name: "Appearance", keys: "theme pywal gaps blur bar layout" },
        { name: "Wallpaper", keys: "background image" },
        { name: "Widgets", keys: "desktop github clock" },
        { name: "Clipboard", keys: "cliphist history copy paste" },
        { name: "Notifications", keys: "dnd do not disturb" },
        { name: "Power", keys: "battery profile session" },
        { name: "Keybinds", keys: "shortcuts keys binds" }
    ]

    readonly property var actions: [
        { name: "Lock", icon: Icons.lock, cmd: Config.lockCommand, danger: false, keys: "screen hyprlock" },
        { name: "Suspend", icon: Icons.suspend, cmd: ["systemctl", "suspend"], danger: false, keys: "sleep" },
        { name: "Log out", icon: Icons.logout, cmd: ["hyprctl", "dispatch", "exit"], danger: true, keys: "logout exit quit hyprland" },
        { name: "Restart", icon: Icons.reboot, cmd: ["systemctl", "reboot"], danger: true, keys: "reboot" },
        { name: "Shut down", icon: Icons.power, cmd: ["systemctl", "poweroff"], danger: true, keys: "shutdown poweroff off" }
    ]

    // ── Calculator ───────────────────────────────────────────────────
    // Small recursive-descent parser: + - * / % ^ and parentheses. No eval.
    function calc(expr) {
        const src = expr.replace(/^=\s*/, "").replace(/×/g, "*").replace(/÷/g, "/").replace(/,/g, ".").replace(/\s+/g, "");
        if (src === "" || !/^[0-9+\-*/%^().]+$/.test(src) || !/\d/.test(src)) return null;
        let i = 0;
        const peek = () => src[i];
        function primary() {
            if (peek() === "(") { i++; const v = sum(); if (peek() !== ")") throw 0; i++; return v; }
            const m = /^\d*\.?\d+/.exec(src.slice(i));
            if (!m) throw 0;
            i += m[0].length;
            return parseFloat(m[0]);
        }
        function unary() { if (peek() === "-") { i++; return -unary(); } if (peek() === "+") { i++; return unary(); } return primary(); }
        function power() { const b = unary(); if (peek() === "^") { i++; return Math.pow(b, power()); } return b; }
        function product() {
            let v = power();
            while ("*/%".includes(peek() ?? "x")) { const op = src[i++]; const r = power(); v = op === "*" ? v * r : op === "/" ? v / r : v % r; }
            return v;
        }
        function sum() {
            let v = product();
            while ("+-".includes(peek() ?? "x")) { const op = src[i++]; const r = product(); v = op === "+" ? v + r : v - r; }
            return v;
        }
        try {
            const v = sum();
            if (i !== src.length || !isFinite(v)) return null;
            return Math.round(v * 1e10) / 1e10;
        } catch (e) {
            return null;
        }
    }

    // ── Search ───────────────────────────────────────────────────────
    // Each result: { kind, title, sub, icon (path) | glyph, hint, danger, run: { type, ... } }
    function search(raw) {
        const text = raw.trim();
        const q = text.toLowerCase();

        if (mode === "run") return runResults(text);
        if (mode === "files") return fileResults();
        if (mode === "window") return windowResults(q);

        // Prefix modes
        if (q.startsWith(":clip")) return clipResults(text.slice(5).trim().toLowerCase());
        if (q.startsWith(":wall")) return wallResults(text.slice(5).trim().toLowerCase());
        if (text.startsWith(">")) {
            const cmd = text.slice(1).trim();
            return cmd === "" ? [] : [{ kind: "run", title: cmd, sub: "Run in background", glyph: String.fromCodePoint(0xF018D),
                                        hint: "shell", run: { type: "shell", cmd: cmd } }];
        }
        if (text.startsWith("?")) {
            const s = text.slice(1).trim();
            return s === "" ? [] : [{ kind: "web", title: s, sub: "Search the web", glyph: String.fromCodePoint(0xF059F),
                                      hint: "web", run: { type: "url", url: Config.launcherSearchUrl + encodeURIComponent(s) } }];
        }

        const out = [];

        // Calculator first when the query is math
        const v = calc(text);
        if (v !== null && (text.startsWith("=") || /[+\-*/^%]/.test(text)))
            out.push({ kind: "calc", title: String(v), sub: text.replace(/^=\s*/, "") + "  ·  Enter to copy",
                       glyph: String.fromCodePoint(0xF00EC), hint: "=", score: 1000, run: { type: "copy", text: String(v) } });

        // Apps
        const apps = DesktopEntries.applications.values.filter(a => !a.noDisplay);
        for (const a of apps) {
            const s = q === "" ? 1 : Math.max(
                score(a.name, q) * 1.2,
                score(a.genericName, q) * 0.8,
                score((a.keywords ?? []).join(" "), q) * 0.6,
                score(a.id, q) * 0.7);
            if (s <= 0) continue;
            out.push({
                kind: "app", title: a.name,
                sub: a.genericName || a.comment || "",
                icon: Quickshell.iconPath(a.icon, true),
                glyph: String.fromCodePoint(0xF03D6),
                hint: "", entry: a,
                score: s + Math.min(30, root.frecency(a.id) * 3),
                run: { type: "app" }
            });
        }

        if (q !== "") {
            for (const p of pages) {
                const s = Math.max(score(p.name, q), score(p.keys, q) * 0.8);
                if (s > 0) out.push({ kind: "page", title: p.name, sub: "Open in Control Center",
                                      glyph: Icons.settings, hint: "page", score: s * 0.9, run: { type: "page", page: p.name } });
            }
            for (const a of actions) {
                const s = Math.max(score(a.name, q), score(a.keys, q) * 0.8);
                if (s > 0) out.push({ kind: "power", title: a.name, sub: a.danger ? "Press Enter twice to confirm" : "Session",
                                      glyph: a.icon, hint: "power", danger: a.danger, score: s * 0.85,
                                      run: { type: "cmd", cmd: a.cmd } });
            }
        }

        out.sort((x, y) => y.score - x.score || x.title.localeCompare(y.title));
        return out.slice(0, 40);
    }

    function runResults(text) {
        const q = text.toLowerCase();
        const out = [];
        if (text !== "")
            out.push({ kind: "run", title: text, sub: "Run", glyph: String.fromCodePoint(0xF018D), hint: "run",
                       run: { type: "shell", cmd: text } });
        for (const c of (history.__runs ?? []))
            if (c !== text && (q === "" || c.toLowerCase().includes(q)))
                out.push({ kind: "run", title: c, sub: "Recent", glyph: String.fromCodePoint(0xF02DA), hint: "recent",
                           run: { type: "shell", cmd: c } });
        return out;
    }

    function fileResults() {
        return files.map(f => {
            const name = f.replace(/\/$/, "").split("/").pop();
            const dir = f.slice(0, f.length - name.length).replace(/\/$/, "");
            const isDir = f.endsWith("/");
            return {
                kind: "file", title: name,
                sub: "~/" + dir,
                glyph: isDir ? String.fromCodePoint(0xF024B) : String.fromCodePoint(0xF0214),
                hint: isDir ? "folder" : "file",
                run: { type: "url", url: "file://" + Config.home + "/" + f }
            };
        });
    }

    function windowResults(q) {
        return ToplevelManager.toplevels.values
            .filter(t => q === "" || (t.title + " " + t.appId).toLowerCase().includes(q))
            .map(t => ({
                kind: "window", title: t.title || t.appId,
                sub: t.appId, icon: iconFor(t.appId),
                glyph: String.fromCodePoint(0xF05B0), hint: "window",
                run: { type: "window", toplevel: t }
            }));
    }

    function clipResults(q) {
        return Clipboard.items
            .filter(i => q === "" || (i.image ? "image " + i.meta : i.text).toLowerCase().includes(q))
            .slice(0, 40)
            .map(i => ({
                kind: "clip",
                title: i.image ? "Image" : i.text.replace(/\s+/g, " ").slice(0, 120),
                sub: i.image ? i.meta : "Enter to copy",
                icon: i.image ? i.thumb : "",
                glyph: Icons.clipboard, hint: "clip",
                run: { type: "clip", item: i }
            }));
    }

    function wallResults(q) {
        return Wallpaper.images
            .filter(p => q === "" || Wallpaper.fileName(p).toLowerCase().includes(q))
            .slice(0, 40)
            .map(p => ({
                kind: "wall", title: Wallpaper.fileName(p),
                sub: p.replace(Config.home, "~"),
                icon: "file://" + p, glyph: Icons.image, hint: "wall",
                run: { type: "wall", path: p }
            }));
    }

    // ── Run ──────────────────────────────────────────────────────────
    // Returns false when nothing should close yet (e.g. waiting for confirmation)
    signal pageRequested(string name)

    function run(r) {
        const x = r.run;
        switch (x.type) {
        case "app":
            remember(r.entry.id);
            r.entry.execute();
            break;
        case "copy":
            Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | wl-copy', "sh", x.text]);
            break;
        case "page":
            pageRequested(x.page.toLowerCase());
            break;
        case "cmd":
            Quickshell.execDetached(x.cmd);
            break;
        case "shell":
            rememberRun(x.cmd);
            Quickshell.execDetached(["sh", "-c", x.cmd]);
            break;
        case "window":
            x.toplevel.activate();
            break;
        case "url":
            Quickshell.execDetached(["xdg-open", x.url]);
            break;
        case "clip":
            Clipboard.copy(x.item);
            break;
        case "wall":
            Wallpaper.set(x.path);
            break;
        }
        open = false;
    }
}
