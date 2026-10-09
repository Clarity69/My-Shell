pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Jaringan via nmcli: radio Wi-Fi, koneksi aktif, Ethernet, scan & connect Wi-Fi.
Singleton {
    id: root

    // Wi-Fi
    property bool enabled: false
    property string wifiDevice: ""
    property string ssid: ""          // nama koneksi Wi-Fi aktif
    property string wifiIp: ""
    property bool busy: false         // radio sedang di-toggle

    // Ethernet
    property string ethDevice: ""
    property bool ethConnected: false
    property string ethIp: ""
    property string ethSpeed: ""

    readonly property bool online: ethConnected || ssid !== ""

    // Scan & connect
    property var networks: []         // [{ ssid, signal, security, secure, active, known, profile }]
    property bool scanning: false
    property string connecting: ""
    property string error: ""

    function unesc(s) { return (s ?? "").replace(/\\:/g, ":"); }

    function refresh() {
        if (!statusProc.running && !busy) statusProc.running = true;
    }

    function toggle() {
        if (busy) return;
        busy = true;
        const target = !enabled;
        enabled = target;
        if (!target) { ssid = ""; networks = []; }
        toggleProc.command = ["nmcli", "radio", "wifi", target ? "on" : "off"];
        toggleProc.running = true;
    }

    function scan(force) {
        if (scanProc.running || !enabled) return;
        scanning = true;
        scanProc.command = ["sh", "-c", scanScript, "sh", force ? "yes" : "auto"];
        scanProc.running = true;
    }

    function connect(net, password) {
        if (connectProc.running) return;
        error = "";
        connecting = net.ssid;
        if (net.known)
            connectProc.command = ["nmcli", "connection", "up", "id", net.profile];
        else if (net.secure)
            connectProc.command = ["nmcli", "device", "wifi", "connect", net.ssid, "password", password];
        else
            connectProc.command = ["nmcli", "device", "wifi", "connect", net.ssid];
        connectProc.running = true;
    }

    function disconnect() {
        if (wifiDevice === "") return;
        Quickshell.execDetached(["nmcli", "device", "disconnect", wifiDevice]);
        ssid = "";
        networks = networks.map(n => Object.assign({}, n, { active: false }));
    }

    // ── Status: radio, Wi-Fi aktif, Ethernet ─────────────────────────
    // Baris: radio | wifiDev | koneksi | wifiIp | ethDev | ethState | ethIp | ethSpeed
    readonly property string statusScript: [
        'echo "$(timeout 3 nmcli radio wifi 2>/dev/null)"',
        'dev=$(timeout 3 nmcli -t -f DEVICE,TYPE,STATE device 2>/dev/null)',
        'w=$(printf "%s\\n" "$dev" | awk -F: \'$2=="wifi" && $3 ~ /^connected/ {print $1; exit}\')',
        'echo "$w"',
        'echo "$( [ -n "$w" ] && nmcli -g GENERAL.CONNECTION device show "$w" 2>/dev/null)"',
        'echo "$( [ -n "$w" ] && ip -4 -o addr show dev "$w" 2>/dev/null | awk \'{print $4; exit}\')"',
        'e=$(printf "%s\\n" "$dev" | awk -F: \'$2=="ethernet" {print; if ($3 ~ /^connected/) exit}\' | tail -n1)',
        'echo "${e%%:*}"',
        'echo "${e##*:}"',
        'echo "$( [ -n "$e" ] && ip -4 -o addr show dev "${e%%:*}" 2>/dev/null | awk \'{print $4; exit}\')"',
        'echo "$( [ -n "$e" ] && cat "/sys/class/net/${e%%:*}/speed" 2>/dev/null)"'
    ].join("\n")

    Process {
        id: statusProc
        command: ["sh", "-c", root.statusScript]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.split("\n");
                root.enabled = l[0] === "enabled";
                root.wifiDevice = l[1] ?? "";
                root.ssid = root.enabled ? root.unesc(l[2]) : "";
                root.wifiIp = l[3] ?? "";
                root.ethDevice = l[4] ?? "";
                root.ethConnected = /^connected/.test(l[5] ?? "");
                root.ethIp = l[6] ?? "";
                const sp = parseInt(l[7]);
                root.ethSpeed = sp > 0 ? (sp >= 1000 ? sp / 1000 + " Gb/s" : sp + " Mb/s") : "";
            }
        }
    }

    Process {
        id: toggleProc
        onExited: (code, status) => {
            root.busy = false;
            root.refresh();
            if (root.enabled) root.scan(false);
        }
    }

    // ── Scan: daftar jaringan + profil tersimpan ─────────────────────
    // N|IN-USE:SIGNAL:SECURITY:SSID     K|ssid|nama-profil
    readonly property string scanScript: [
        'timeout 15 nmcli -t -f IN-USE,SIGNAL,SECURITY,SSID device wifi list --rescan "$1" 2>/dev/null | sed "s/^/N|/"',
        'nmcli -t -f NAME,TYPE connection show 2>/dev/null | while IFS= read -r l; do',
        '  case "$l" in *:802-11-wireless)',
        '    n=$(printf "%s" "${l%:802-11-wireless}" | sed \'s/\\\\:/:/g\')',
        '    echo "K|$(nmcli -g 802-11-wireless.ssid connection show id "$n" 2>/dev/null)|$n";;',
        '  esac',
        'done'
    ].join("\n")

    Process {
        id: scanProc
        stdout: StdioCollector {
            onStreamFinished: {
                const known = {};
                const found = {};
                for (const line of text.split("\n")) {
                    if (line.startsWith("K|")) {
                        const p = line.slice(2).split("|");
                        known[root.unesc(p[0])] = p.slice(1).join("|");
                    }
                }
                for (const line of text.split("\n")) {
                    if (!line.startsWith("N|")) continue;
                    const s = line.slice(2);
                    const a = s.indexOf(":"), b = s.indexOf(":", a + 1), c = s.indexOf(":", b + 1);
                    if (c < 0) continue;
                    const ssid = root.unesc(s.slice(c + 1));
                    if (ssid === "") continue;
                    const security = s.slice(b + 1, c);
                    const net = {
                        ssid: ssid,
                        signal: parseInt(s.slice(a + 1, b)) || 0,
                        security: security === "" || security === "--" ? "open" : security,
                        secure: security !== "" && security !== "--",
                        active: s.slice(0, a).trim() === "*",
                        known: known[ssid] !== undefined,
                        profile: known[ssid] ?? ssid
                    };
                    const prev = found[ssid];
                    if (!prev || net.active || (!prev.active && net.signal > prev.signal)) found[ssid] = net;
                }
                root.networks = Object.values(found).sort((x, y) =>
                    (y.active - x.active) || (y.known - x.known) || (y.signal - x.signal));
            }
        }
        onExited: root.scanning = false
    }

    Process {
        id: connectProc
        stderr: StdioCollector {
            onStreamFinished: if (text.trim() !== "") root.error = text.trim().split("\n").pop()
        }
        onExited: (code, status) => {
            root.connecting = "";
            root.refresh();
            root.scan(false);
        }
    }

    Component.onCompleted: refresh()
}
