pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Warna, ukuran, font. Warna diambil dari pywal (~/.cache/wal/colors.json)
// dan diperbarui otomatis setiap pywal menulis ulang file itu.
// Tanpa pywal, palet bawaan hitam-krem yang dipakai.
Singleton {
    id: root

    // ── Tiga warna dasar; semua warna lain diturunkan dari sini ──────
    property color base: "#141113"     // latar
    property color ink: "#ece3d6"      // teks
    property color hot: "#e9a6ae"      // aksen data/bahaya
    property var palette: []           // color0..color15 untuk preview
    property bool walActive: false

    function mix(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1);
    }

    readonly property color bg:       base
    readonly property color bgAlt:    mix(base, ink, 0.03)   // sidebar
    readonly property color surface:  mix(base, ink, 0.06)
    readonly property color surface2: mix(base, ink, 0.12)
    readonly property color border:   mix(base, ink, 0.13)
    readonly property color text:     ink
    readonly property color subtext:  mix(ink, base, 0.35)
    readonly property color muted:    mix(ink, base, 0.58)
    readonly property color accent:   ink      // item aktif = blok warna teks
    readonly property color accentFg: base
    readonly property color rose:     hot
    readonly property color danger:   hot

    // ── Ukuran ───────────────────────────────────────────────────────
    readonly property int windowWidth: 820
    readonly property int windowHeight: 600
    readonly property int sidebarWidth: 210
    readonly property int barHeight: 30
    readonly property int padding: 16
    readonly property int gap: 10
    readonly property int radius: 8
    readonly property int radiusSmall: 4

    // ── Font: mono untuk UI (Nerd Font untuk ikon), serif untuk judul ─
    readonly property string font: "JetBrainsMono Nerd Font"
    readonly property string serif: "serif"
    readonly property int fontSize: 13
    readonly property int iconSize: 18

    // ── pywal ────────────────────────────────────────────────────────
    FileView {
        path: Config.walColors
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.applyWal(text())
    }

    function applyWal(raw) {
        let j;
        try { j = JSON.parse(raw); } catch (e) { return; }   // file setengah ditulis: abaikan
        if (!j.special || !j.colors) return;

        const cols = [];
        for (let i = 0; i < 16; i++) cols.push(j.colors["color" + i]);

        // Aksen = warna color1..color6 yang paling "berwarna" dan cukup terang
        let best = cols[1], score = -1;
        for (let i = 1; i <= 6; i++) {
            const c = Qt.lighter(cols[i], 1.0);
            const s = c.hslSaturation * (c.hslLightness > 0.35 ? 1 : 0.4);
            if (s > score) { score = s; best = cols[i]; }
        }

        base = j.special.background;
        ink = j.special.foreground;
        hot = best;
        palette = cols;
        walActive = true;
    }
}
