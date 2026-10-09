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

    // Frontend: picker rofi milikmu, dibuka lewat tombol "Open picker".
    readonly property string wallpaperPicker: home + "/.local/bin/wallset"

    // ── Hyprland ─────────────────────────────────────────────────────
    // Halaman Appearance menulis nilai ke file ini. Agar permanen, tambahkan
    // `source = ~/.config/hypr/quickshell.conf` di AKHIR hyprland.conf.
    readonly property string hyprOverrides: home + "/.config/hypr/quickshell.conf"

    // ── Lain-lain ────────────────────────────────────────────────────
    readonly property int nightLightDefault: 4500
    readonly property var lockCommand: ["sh", "-c", "pidof hyprlock || hyprlock"]
}
