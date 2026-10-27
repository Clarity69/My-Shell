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

    // ── Widget GitHub (desktop) ──────────────────────────────────────
    readonly property bool githubWidget: true
    readonly property string githubUser: ""        // kosong = akun yang login di `gh`
    readonly property string githubPosition: "bottom-left"   // top-left | top-right | bottom-left | bottom-right
    readonly property string githubScreen: ""      // nama monitor, mis. "VGA-1"; kosong = monitor pertama
    readonly property int githubMargin: 24
    readonly property int githubCellSize: 11
    readonly property bool githubCardBackground: true
    readonly property int githubRefreshMinutes: 30
    readonly property string githubScript: home + "/.config/quickshell/shell/bin/github-contrib"
    readonly property string githubCache: home + "/.cache/quickshell/github-contrib.txt"
    // ── Widget jam desktop ───────────────────────────────────────────
    readonly property bool clockWidget: true
    readonly property string clockPosition: "top-left"

    // Pengaturan dari halaman Widgets disimpan di sini (menimpa nilai default di atas)
    readonly property string widgetStateFile: home + "/.cache/quickshell/widgets.json"

    // ── Hyprland ─────────────────────────────────────────────────────
    // Halaman Appearance menulis nilai ke file ini. Agar permanen, tambahkan
    // `load("quickshell")` di AKHIR hyprland.lua.
   readonly property string hyprOverrides: home + "/.config/hypr/quickshell.lua"

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

    // ── Cuaca (Open-Meteo, tanpa API key; butuh curl + jq) ───────────
    // Tampil di popup kalender + modul bar "weather".
    readonly property bool weatherEnabled: true
    // Kosong = lokasi otomatis dari IP. Isi kalau hasil IP meleset, mis. "-6.2" / "106.8"
    readonly property string weatherLat: ""
    readonly property string weatherLon: ""
    readonly property string weatherCity: ""          // nama yang ditampilkan; kosong = dari IP
    readonly property int weatherRefreshMinutes: 30
    readonly property string weatherScript: home + "/.config/quickshell/shell/bin/weather"
    readonly property string weatherCache: home + "/.cache/quickshell/weather.json"

    // ── Dynamic island ───────────────────────────────────────────────
    // Tampil di tengah bar untuk layout yang punya `island: true` (mis. layout "island")
    readonly property bool islandEnabled: true
    readonly property bool islandOsd: true            // volume & kecerahan muncul di island
    readonly property bool islandNotifications: true  // notifikasi muncul di island, bukan popup
    readonly property bool islandWorkspaceHint: true  // "Workspace 2" sebentar saat pindah workspace
    readonly property int islandHeight: 34            // tinggi pil saat ringkas
    readonly property string islandFont: "Inter"      // font sans tebal ala Tide (pacman -S inter-font)
    readonly property string islandClockFormat: "hh:mm"   // "hh:mm ap" = 04:57 pm
    readonly property bool islandUseTheme: false      // false = hitam-putih seperti Tide, true = warna pywal

    // ── Workspace overview ───────────────────────────────────────────
    readonly property int overviewWorkspaces: 5      // 1..N selalu tampil walau kosong
    readonly property int overviewColumns: 5         // workspace per baris
    readonly property bool overviewLive: false       // true = preview bergerak (lebih berat)

    readonly property bool launcherBuiltin: true
    readonly property string launcherHistory: home + "/.cache/quickshell/launcher.json"
    readonly property string launcherSearchUrl: "https://duckduckgo.com/?q="

    // readonly property string externalMode: "1920x1080@60"

    // ── Mouse battery (2.4 GHz YJX-CHIP receiver, bin/mouse-battery) ──
    readonly property bool mouseBattery: true
    readonly property string mouseBatteryScript: home + "/.config/quickshell/shell/bin/mouse-battery"
    readonly property int mouseBatteryInterval: 60       // seconds
    readonly property int mouseLowBattery: 15            // percent, warns once below this
}
