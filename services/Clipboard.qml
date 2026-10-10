pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Riwayat clipboard via cliphist (+ wl-clipboard).
//   copy(item)   : salin ulang ke clipboard (cliphist decode | wl-copy)
//   remove(item) : hapus satu entri
//   wipe()       : hapus semua
// Gambar di-decode sekali ke Config.clipCacheDir untuk thumbnail.
// Butuh di hyprland.conf:
//   exec-once = wl-paste --type text  --watch cliphist store
//   exec-once = wl-paste --type image --watch cliphist store
Singleton {
    id: root

    property bool available: false
    property var items: []          // [{ id, text, image, thumb, meta }]
    property bool loading: false
    property string copied: ""      // id terakhir yang disalin (umpan balik UI)

    function refresh() {
        if (listProc.running) return;
        loading = true;
        listProc.running = true;
    }

    function copy(item) {
        Quickshell.execDetached(["sh", "-c",
            'printf "%s\\t\\n" "$1" | cliphist decode | wl-copy', "sh", item.id]);
        copied = item.id;
        copiedReset.restart();
    }

    function remove(item) {
        Quickshell.execDetached(["sh", "-c",
            'printf "%s\\n" "$1" | cliphist delete; [ -n "$2" ] && rm -f "$2"',
            "sh", item.raw, item.thumb.replace("file://", "")]);
        items = items.filter(i => i.id !== item.id);
    }

    function wipe() {
        Quickshell.execDetached(["sh", "-c", 'cliphist wipe; rm -rf "$1"', "sh", Config.clipCacheDir]);
        items = [];
    }

    Timer { id: copiedReset; interval: 1500; onTriggered: root.copied = "" }

    // Baris output:  E|id|teks-preview          (entri teks)
    //                I|id|path-thumbnail|meta   (entri gambar, mis. "png 1920x1080")
    //                R|raw-line                 (baris asli, untuk delete)
    readonly property string script: [
        'command -v cliphist >/dev/null || { echo none; exit 0; }',
        'echo ok',
        'mkdir -p "$1"',
        'n=0',
        'cliphist list | head -n "$2" | while IFS= read -r line; do',
        '  id="${line%%\t*}"; txt="${line#*\t}"',
        '  printf "R|%s\\n" "$line"',
        '  case "$txt" in',
        '    "[[ binary data"*)',
        '      ext=$(printf "%s" "$txt" | grep -oE "(png|jpe?g|webp|gif|bmp)" | head -n1)',
        '      meta=$(printf "%s" "$txt" | sed -E "s/^\\[\\[ binary data (.*) \\]\\]$/\\1/")',
        '      f="$1/$id.${ext:-png}"',
        '      n=$((n+1))',
        '      if [ -n "$ext" ] && [ ! -s "$f" ] && [ "$n" -le "$3" ]; then printf "%s\\t\\n" "$id" | cliphist decode > "$f" 2>/dev/null; fi',
        '      [ -s "$f" ] || f=""',
        '      printf "I|%s|%s|%s\\n" "$id" "$f" "$meta";;',
        '    *) printf "E|%s|%s\\n" "$id" "$txt";;',
        '  esac',
        'done'
    ].join("\n")

    Process {
        id: listProc
        command: ["sh", "-c", root.script, "sh", Config.clipCacheDir, String(Config.clipLimit), "24"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.split("\n");
                root.available = l[0] === "ok";
                const out = [];
                let raw = "";
                for (const line of l.slice(1)) {
                    if (line.startsWith("R|")) { raw = line.slice(2); continue; }
                    const p = line.split("|");
                    if (p[0] === "E") {
                        out.push({ id: p[1], raw: raw, image: false, thumb: "", meta: "",
                                   text: p.slice(2).join("|") });
                    } else if (p[0] === "I") {
                        out.push({ id: p[1], raw: raw, image: true,
                                   thumb: p[2] ? "file://" + p[2] : "", meta: p.slice(3).join("|"),
                                   text: "" });
                    }
                }
                root.items = out;
                root.loading = false;
            }
        }
    }
}
