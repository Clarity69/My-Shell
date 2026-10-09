pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Wallpaper: hanya menampilkan gambar dan MEMANGGIL skrip milikmu.
//   set(path)    -> Config.wallpaperSet   (backend: awww + pywal + dst.)
//   openPicker() -> Config.wallpaperPicker (frontend milikmu, opsional)
// Warna Control Center ikut berubah karena Theme.qml memantau colors.json pywal.
Singleton {
    id: root

    property string current: ""       // dibaca dari `awww query` (fallback swww)
    property var images: []
    property string applying: ""
    property bool loading: false
    property string error: ""

    readonly property bool hasPicker: Config.wallpaperPicker !== ""

    function refresh() {
        if (listProc.running) return;
        loading = true;
        listProc.running = true;
    }

    function set(path) {
        if (setProc.running) return;
        error = "";
        applying = path;
        // stdout/stderr ke file log, stdin dari /dev/null: proses latar yang dijalankan
        // backend (waybar, spicetify) tidak memegang pipe Quickshell.
        setProc.command = ["sh", "-c",
            Config.wallpaperSet + ' </dev/null >"$2" 2>&1', "sh", path, Config.wallpaperLog];
        setProc.running = true;
    }

    function openPicker() {
        if (hasPicker) Quickshell.execDetached(["sh", "-c", Config.wallpaperPicker]);
    }

    function fileName(path) { return path.split("/").pop(); }

    readonly property string script: [
        't=$(command -v awww || command -v swww)',
        'echo "$( [ -n "$t" ] && "$t" query 2>/dev/null | grep -m1 -oE "image: .*" | sed "s/^image: //")"',
        'find -L "$1" -maxdepth 2 -type f \\( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \\) 2>/dev/null | sort'
    ].join("\n")

    Process {
        id: listProc
        command: ["sh", "-c", root.script, "sh", Config.wallpaperDir]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.split("\n");
                root.current = l[0] ?? "";
                root.images = l.slice(1).filter(p => p !== "");
                root.loading = false;
            }
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim() !== "") root.error = text.trim().split("\n").pop()
        }
        // Jaring pengaman: kalau stdout tidak pernah selesai, jangan terjebak "loading"
        onExited: (code, status) => {
            if (code !== 0 && root.error === "") root.error = "Gagal membaca folder (kode " + code + ")";
            listTimeout.restart();
        }
    }

    Timer {
        id: listTimeout
        interval: 1500
        onTriggered: if (root.loading) {
            root.loading = false;
            if (root.error === "") root.error = "Proses selesai tapi output tidak terbaca.";
        }
    }

    Process {
        id: setProc
        onExited: (code, status) => {
            if (code === 0) root.current = root.applying;
            else root.error = "wallset-backend gagal (kode " + code + "). Lihat " +
                              Config.wallpaperLog.replace(Config.home, "~");
            root.applying = "";
        }
    }
}
