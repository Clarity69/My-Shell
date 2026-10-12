pragma Singleton

import QtQuick
import Quickshell

// Preferensi pribadi: path dan perintah eksternal. Sesuaikan dengan setup kamu.
Singleton {
    readonly property string home: Quickshell.env("HOME")

    // ── pywal ────────────────────────────────────────────────────────
    // Theme.qml memantau file ini; begitu pywal menulis ulang, warna ikut berubah.
    readonly property string walColors: home + "/.cache/wal/colors.json"

    // ── Wallpaper: memakai skrip milikmu sendiri ─────────────────────
    // Folder yang ditampilkan sebagai grid di halaman Wallpaper.
    // Sama dengan WALL_DIR di skrip wallset.
    readonly property string wallpaperDir: home + "/Pictures/Wallpaper"

    // Backend: dipanggil saat thumbnail diklik. "$1" = path gambar.
    // wallset-backend yang mengurus awww + pywal + kitty/waybar/dst.
    // Path lengkap: exec-once Hyprland tidak selalu punya ~/.local/bin di PATH.
    readonly property string wallpaperSet: home + "/.local/bin/wallset-backend \"$1\""

    // Output backend ditulis ke sini (bukan ke Quickshell), supaya proses yang
    // di-restart backend (mis. waybar) tidak ikut terikat ke Quickshell.
    readonly property string wallpaperLog: home + "/.cache/wallset-backend.log"

    // Frontend: picker milikmu, dibuka lewat tombol "Open picker" (Control Center ikut ditutup).
    // Sama dengan bind SUPER+K. Picker rofi lama: home + "/.local/bin/wallset"
    readonly property string wallpaperPicker: "quickshell -c hyprquickpaper"

    // ── Clipboard (cliphist) ─────────────────────────────────────────
    readonly property int clipLimit: 80                                  // entri yang ditampilkan
    readonly property string clipCacheDir: home + "/.cache/quickshell/clipboard"   // thumbnail gambar

    // ── Notifikasi (Quickshell sebagai daemon, swaync harus dimatikan) ──
    readonly property string notifPosition: "top-right"     // "top-right" | "bottom-right"
    readonly property int notifTimeout: 6000                 // ms, 0 = tidak hilang sendiri
    readonly property int notifMaxPopups: 4
    readonly property int notifWidth: 360
    readonly property string notifStateFile: home + "/.cache/quickshell/notif-dnd"

    // ── Hyprland ─────────────────────────────────────────────────────
    // Halaman Appearance menulis nilai ke file ini. Agar permanen, tambahkan
    // `source = ~/.config/hypr/quickshell.conf` di AKHIR hyprland.conf.
    readonly property string hyprOverrides: home + "/.config/hypr/quickshell.conf"

    // ── Lain-lain ────────────────────────────────────────────────────
    readonly property int nightLightDefault: 4500
    readonly property var lockCommand: ["sh", "-c", "pidof hyprlock || hyprlock"]

    // ── Bar ──────────────────────────────────────────────────────────
    // Bar Quickshell (pengganti Waybar). false = tidak ditampilkan saat start;
    // tetap bisa dimunculkan lewat: quickshell -p ~/.config/quickshell/shell ipc call bar toggle
    readonly property bool barEnabled: true
    // Layout awal kalau belum pernah dipilih (lihat bar/BarState.qml)
    readonly property string barLayout: "omarchy"
    // Layout terakhir yang dipilih disimpan di sini
    readonly property string barStateFile: home + "/.cache/quickshell/bar-layout"
    // Dijalankan tombol launcher di bar
    readonly property string launcherCommand: "pkill rofi || rofi -show drun"
    // Kalender muncul saat jam di-hover (klik kanan tetap bisa dipakai)
    readonly property bool calendarOnHover: true

    // ── Workspace overview ───────────────────────────────────────────
    readonly property int overviewWorkspaces: 5      // 1..N selalu tampil walau kosong
    readonly property int overviewColumns: 5         // workspace per baris
    readonly property bool overviewLive: false       // true = preview bergerak (lebih berat)
}
