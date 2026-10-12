// Satu modul bar, dipilih dari nama di layout ("clock", "workspaces:kanji", ...).
// Menambah modul baru = tambah Component di bawah + daftarkan di `comps`.

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.overview

Item {
    id: root

    required property string spec
    required property var monitor
    required property var window
    required property var layout

    signal openPage(string name)
    signal toggleControl()

    readonly property string kind: spec.split(":")[0]
    readonly property string arg: spec.split(":")[1] ?? ""
    readonly property bool bordered: layout.style === "border"

    readonly property var comps: ({
        workspaces: workspacesC, window: windowC,
        clock: clockC, date: dateC, datetime: datetimeC,
        launcher: launcherC, power: powerC, control: controlC,
        network: networkC, bluetooth: bluetoothC,
        volume: volumeC, mic: micC, brightness: brightnessC, battery: batteryC,
        cpu: cpuC, memory: memoryC, profile: profileC,
        notification: notificationC, tray: trayC, clipboard: clipboardC, overview: overviewC
    })

    // Modul yang datanya tidak tersedia disembunyikan (mis. baterai di PC desktop)
    visible: ({
        bluetooth: Bluetooth.powered,
        mic: Audio.hasMic,
        brightness: Brightness.available,
        battery: Battery.available,
        profile: PowerProfile.available
    })[kind] ?? true
    implicitWidth: frame.implicitWidth
    implicitHeight: frame.implicitHeight

    Rectangle {
        id: frame
        implicitWidth: loader.implicitWidth + (root.bordered ? 12 : 0)
        implicitHeight: root.layout.height - (root.bordered ? 12 : 6)
        color: "transparent"
        radius: root.layout.radius
        border.width: root.bordered ? 1 : 0
        border.color: Theme.border

        Loader {
            id: loader
            anchors.centerIn: parent
            sourceComponent: root.comps[root.kind] ?? unknownC
        }
    }

    // ── Komponen ─────────────────────────────────────────────────────

    Component {
        id: workspacesC
        Workspaces {
            monitor: root.monitor
            numerals: root.arg
            itemHeight: root.layout.height - 10
        }
    }

    Component {
        id: windowC
        Text {
            width: Math.min(implicitWidth, 320)
            // "window" = judul window, "window:app" = nama aplikasi saja
            text: {
                const t = ToplevelManager.activeToplevel;
                if (!t) return "";
                if (root.arg !== "app") return t.title;
                // "org.mozilla.firefox" -> "Firefox", "kitty" -> "Kitty"
                const id = (t.appId || "").split(".").pop();
                return id.charAt(0).toUpperCase() + id.slice(1);
            }
            color: Theme.subtext
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 2
            elide: Text.ElideRight
        }
    }

    // Jam: klik kanan / hover = kalender, klik kiri = halaman Profile
    Component {
        id: clockC
        ClockItem {
            barWindow: root.window
            format: "hh:mm"
            labelColor: Theme.text
            onClicked: root.openPage("profile")
        }
    }
    Component {
        id: dateC
        ClockItem {
            barWindow: root.window
            format: "ddd dd MMM"
            onClicked: root.openPage("profile")
        }
    }
    Component {
        id: datetimeC
        ClockItem {
            barWindow: root.window
            format: "ddd dd MMM   hh:mm"
            labelColor: Theme.text
            onClicked: root.openPage("profile")
        }
    }

    Component {
        id: launcherC
        BarItem {
            icon: Icons.arch
            onClicked: Quickshell.execDetached(["sh", "-c", Config.launcherCommand])
        }
    }

    Component {
        id: powerC
        BarItem {
            icon: Icons.power
            iconColor: Theme.danger
            onClicked: root.openPage("power")
        }
    }

    Component {
        id: controlC
        BarItem {
            icon: Icons.settings
            onClicked: root.toggleControl()
            onRightClicked: root.openPage("profile")
        }
    }

    Component {
        id: networkC
        BarItem {
            icon: Network.ethConnected ? Icons.ethernet
                : Network.ssid !== "" ? Icons.wifi : Icons.wifiOff
            label: Network.ethConnected ? "LAN"
                 : Network.ssid !== "" ? Network.ssid : "offline"
            dimmed: !Network.online
            onClicked: root.openPage("network")
        }
    }

    Component {
        id: bluetoothC
        BarItem {
            visible: Bluetooth.powered
            icon: Bluetooth.device !== "" ? Icons.bluetoothOn : Icons.bluetooth
            label: Bluetooth.device
            onClicked: root.openPage("bluetooth")
        }
    }

    Component {
        id: volumeC
        BarItem {
            icon: Audio.muted ? Icons.volumeOff : Icons.volume
            label: Math.round(Audio.volume * 100) + "%"
            dimmed: Audio.muted
            onClicked: root.openPage("sound")
            onRightClicked: Audio.toggleMute()
            onScrolled: d => Audio.setVolume(Audio.volume + (d > 0 ? 0.05 : -0.05))
        }
    }

    Component {
        id: micC
        BarItem {
            visible: Audio.hasMic
            icon: Audio.micMuted ? Icons.micOff : Icons.mic
            dimmed: Audio.micMuted
            onClicked: Audio.toggleMicMute()
            onRightClicked: root.openPage("sound")
            onScrolled: d => Audio.setMicVolume(Audio.micVolume + (d > 0 ? 0.05 : -0.05))
        }
    }

    Component {
        id: brightnessC
        BarItem {
            visible: Brightness.available
            icon: Icons.brightness
            label: Math.round(Brightness.value * 100) + "%"
            onClicked: root.openPage("display")
            onScrolled: d => Brightness.setValue(Brightness.value + (d > 0 ? 0.05 : -0.05))
        }
    }

    Component {
        id: batteryC
        BarItem {
            visible: Battery.available
            icon: Battery.charging ? Icons.charging : Icons.battery
            label: Battery.percent + "%"
            iconColor: Battery.percent <= 15 && !Battery.charging ? Theme.danger : Theme.text
            onClicked: root.openPage("power")
        }
    }

    Component {
        id: cpuC
        BarItem {
            icon: Icons.cpu
            label: Math.round(SystemStats.cpu * 100) + "%"
            iconColor: SystemStats.cpu > 0.8 ? Theme.rose : Theme.text
            onClicked: root.openPage("profile")
        }
    }

    Component {
        id: memoryC
        BarItem {
            icon: Icons.memory
            label: Math.round(SystemStats.mem * 100) + "%"
            onClicked: root.openPage("profile")
        }
    }

    Component {
        id: profileC
        BarItem {
            visible: PowerProfile.available
            icon: PowerProfile.current === "performance" ? Icons.speed
                : PowerProfile.current === "power-saver" ? Icons.leaf : Icons.balance
            // Klik = ganti ke mode berikutnya
            onClicked: {
                const p = PowerProfile.profiles;
                if (p.length > 0) PowerProfile.set(p[(p.indexOf(PowerProfile.current) + 1) % p.length]);
            }
            onRightClicked: root.openPage("power")
        }
    }

    Component {
        id: notificationC
        BarItem {
            icon: Notifications.dnd ? Icons.bellOff : Icons.bell
            label: Notifications.count > 0 ? String(Notifications.count) : ""
            iconColor: Notifications.count > 0 && !Notifications.dnd ? Theme.rose : Theme.text
            // Kiri = panel notifikasi di bawah bar, kanan = DND, tengah = clear all
            onClicked: Notifications.toggleCenter()
            onRightClicked: Notifications.toggle()
            onMiddleClicked: Notifications.clearAll()
        }
    }

    Component {
        id: overviewC
        BarItem {
            icon: Icons.overview
            onClicked: OverviewState.toggle()
        }
    }

    Component {
        id: clipboardC
        BarItem {
            icon: Icons.clipboard
            onClicked: root.openPage("clipboard")
        }
    }

    Component {
        id: trayC
        // Bungkus dengan padding supaya tray tidak menempel ke modul sebelah
        Item {
            visible: tray.visible
            implicitWidth: tray.implicitWidth + 16 // 8px kiri + 8px kanan
            implicitHeight: tray.implicitHeight

            Tray {
                id: tray
                anchors.centerIn: parent
                window: root.window
            }
        }
    }
    Component {
        id: unknownC
        BarText { text: "?" + root.spec; color: Theme.danger }
    }
}
