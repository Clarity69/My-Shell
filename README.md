<div align="center">

# Control Center

**Window settings minimalis untuk Hyprland, dibangun dengan [Quickshell](https://quickshell.org).**
Warna mengikuti pywal secara live · 9 halaman · tanpa daemon tambahan

<img src="screenshots/dashboard.png" alt="Halaman Profile" width="820">

</div>

---

## Preview

<table>
  <tr>
    <td width="50%"><img src="screenshots/Network.png" alt="Network"><br><sub><b>Network</b> — Ethernet, Wi-Fi, scan & connect</sub></td>
    <td width="50%"><img src="screenshots/bluetooth.png" alt="Bluetooth"><br><sub><b>Bluetooth</b> — perangkat ter-pair</sub></td>
  </tr>
  <tr>
    <td><img src="screenshots/sound.png" alt="Sound"><br><sub><b>Sound</b> — volume, mic, output/input</sub></td>
    <td><img src="screenshots/display.png" alt="Display"><br><sub><b>Display</b> — kecerahan & night light</sub></td>
  </tr>
  <tr>
    <td><img src="screenshots/appearance.png" alt="Appearance"><br><sub><b>Appearance</b> — palet pywal & opsi Hyprland</sub></td>
    <td><img src="screenshots/wallpaper.png" alt="Wallpaper"><br><sub><b>Wallpaper</b> — grid thumbnail</sub></td>
  </tr>
  <tr>
    <td><img src="screenshots/power.png" alt="Power"><br><sub><b>Power</b> — baterai, mode daya, sesi</sub></td>
    <td><img src="screenshots/keybinds.png" alt="Keybinds"><br><sub><b>Keybinds</b> — semua bind dengan filter</sub></td>
  </tr>
</table>

<details>
<summary><b>pywal live</b> — warna berubah mengikuti wallpaper</summary>
<br>
<p align="center">
  <img src="screenshots/pywal-1.png" alt="Palet pywal 1" width="49%">
  <img src="screenshots/pywal-2.png" alt="Palet pywal 2" width="49%">
</p>
</details>

---

## Fitur

| Halaman | Isi | Backend |
|---|---|---|
| **Profile** | hostname, telemetri live (suhu, CPU, RAM, jaringan), quick settings, info sistem | `/proc`, `/sys` |
| **Network** | status Ethernet (IP, kecepatan), Wi-Fi on/off, scan, connect & disconnect | `nmcli` |
| **Bluetooth** | power, perangkat ter-pair, connect & disconnect | `bluetoothctl` |
| **Sound** | volume & mic, pilih output/input default | `wpctl` |
| **Display** | kecerahan, night light + suhu warna, info monitor | `brightnessctl`, `hyprsunset` |
| **Appearance** | palet pywal, gaps/border/rounding/blur/animasi, Do Not Disturb | `hyprctl`, swaync/mako/dunst |
| **Wallpaper** | grid thumbnail; klik untuk memanggil skrip wallpaper milikmu | `wallset-backend` |
| **Power** | baterai, mode daya, lock/suspend/logout/restart/shutdown | `upower`, `powerprofilesctl` |
| **Keybinds** | semua bind aktif dengan filter | `hyprctl binds` |

**Shortcut di dalam window**

| Tombol | Aksi |
|---|---|
| `Ctrl` + `1`…`9` | pindah halaman |
| `Ctrl` + `F` | cari pengaturan |
| `Esc` | hapus pencarian / tutup window |

---

## Struktur

```
Shell/
├── shell.qml               # entry point: ShellRoot + IpcHandler
├── ControlCenter.qml       # FloatingWindow: daftar halaman, sidebar, StackLayout
├── config/
│   ├── Config.qml          # preferensi: folder wallpaper, skrip & picker, path
│   ├── Theme.qml           # warna dari pywal, ukuran, font
│   └── Icons.qml           # glyph Nerd Font
├── components/             # UI murni, tanpa perintah shell
├── pages/                  # satu file per halaman
├── services/               # satu singleton per sumber data / CLI
├── bin/controlcenter       # launcher: toggle/open/start/restart, satu instance
├── screenshots/            # gambar untuk README ini
├── hyprland.conf.snippet
└── waybar.snippet
```

`components/` tidak pernah menjalankan perintah dan `services/` tidak pernah menggambar UI.
Polling hanya berjalan untuk halaman yang sedang terbuka.

---

## Dependensi

**Wajib:** `quickshell` (≥ 0.2), `networkmanager`, `bluez` + `bluez-utils`, `wireplumber`, Nerd Font (default `JetBrainsMono Nerd Font`).

**Opsional** (fitur terkait disembunyikan atau dinonaktifkan kalau tidak ada): `brightnessctl`, `hyprsunset`, `awww`, `python-pywal`, `upower`, `power-profiles-daemon`, `swaync` / `mako` / `dunst`, `hyprlock`.

```sh
sudo pacman -S quickshell networkmanager bluez bluez-utils wireplumber brightnessctl \
               hyprsunset upower power-profiles-daemon ttf-jetbrains-mono-nerd
```

---

## Instalasi

```sh
git https://github.com/Clarity69/My-Shell.git
quickshell -p ~/Documents/Shell
# terminal lain
quickshell -p ~/Documents/Shell ipc call controlcenter toggle
```

### Launcher

`bin/controlcenter` membuka/menutup window dan menyalakan Quickshell kalau belum jalan,
serta menjamin hanya ada satu instance:

```sh
install -m 755 ~/Documents/Shell/bin/controlcenter ~/.local/bin/controlcenter

controlcenter              # toggle
controlcenter open sound   # buka halaman tertentu
controlcenter start        # nyalakan di latar (untuk exec-once)
controlcenter restart      # matikan semua instance, start ulang satu
```

### Hyprland

Tambahkan ke `~/.config/hypr/hyprland.conf` (lengkapnya di `hyprland.conf.snippet`):

```ini
exec-once = ~/.local/bin/controlcenter start
bind = SUPER, A, exec, ~/.local/bin/controlcenter

windowrule = float, title:^(Control Center)$
windowrule = center, title:^(Control Center)$
windowrule = pin, title:^(Control Center)$

# paling akhir: menyimpan pengaturan dari halaman Appearance
source = ~/.config/hypr/quickshell.conf
```

### Waybar

```jsonc
"custom/control": {
    "format": "󰒓",
    "tooltip-format": "Control Center",
    "on-click": "~/.local/bin/controlcenter",
    "on-click-right": "~/.local/bin/controlcenter open network"
}
```

Gaya CSS dan contoh untuk modul bawaan ada di `waybar.snippet`.

---

## IPC

```sh
quickshell -p ~/Documents/Shell ipc call controlcenter toggle
quickshell -p ~/Documents/Shell ipc call controlcenter show
quickshell -p ~/Documents/Shell ipc call controlcenter hide
quickshell -p ~/Documents/Shell ipc call controlcenter open <halaman>
```

`<halaman>`: `profile` `network` `bluetooth` `sound` `display` `appearance` `wallpaper` `power` `keybinds`

---

## Konfigurasi

Semua path dan perintah eksternal ada di `config/Config.qml`:

| Opsi | Default | Keterangan |
|---|---|---|
| `walColors` | `~/.cache/wal/colors.json` | dipantau Theme; warna ikut berubah saat pywal menulis ulang |
| `wallpaperDir` | `~/Pictures/Wallpaper` | folder yang ditampilkan di halaman Wallpaper |
| `wallpaperSet` | `~/.local/bin/wallset-backend "$1"` | dipanggil saat thumbnail diklik (`$1` = path gambar) |
| `wallpaperPicker` | `~/.local/bin/wallset` | dibuka lewat tombol *Open picker* |
| `wallpaperLog` | `~/.cache/wallset-backend.log` | output backend |
| `hyprOverrides` | `~/.config/hypr/quickshell.conf` | ditulis oleh halaman Appearance |
| `nightLightDefault` | `4500` | suhu night light awal (K) |

Warna, ukuran window, dan font ada di `config/Theme.qml`.

---

## Membuat screenshot

Gambar di README ini dibaca dari folder `screenshots/`. Untuk membuatnya, buka halaman yang diinginkan lalu tangkap window yang aktif:

```sh
mkdir -p ~/Documents/Shell/screenshots
cd ~/Documents/Shell/screenshots

# tangkap window Control Center (fokuskan dulu window-nya)
sleep 2 && grim -g "$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')" profile.png
```

Atau pakai `hyprshot -m window -o . -f profile.png`.

Nama file yang dipakai README: `profile.png`, `network.png`, `bluetooth.png`, `sound.png`, `display.png`, `appearance.png`, `wallpaper.png`, `power.png`, `keybinds.png`, `pywal-1.png`, `pywal-2.png`.

---

## Catatan

- **mako DND** butuh mode di config mako: `[mode=do-not-disturb]` + `invisible=1`.
- **Wi-Fi tersimpan** dikenali dari SSID profil NetworkManager; jaringan baru yang terkunci meminta password di baris jaringannya.
- **Restart / Shut down** langsung dieksekusi tanpa konfirmasi.
- Pengaturan di halaman Appearance diterapkan lewat `hyprctl keyword` dan baru permanen kalau `quickshell.conf` di-`source` dari `hyprland.conf`.
