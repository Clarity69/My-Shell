// Tampilan: palet pywal, opsi Hyprland (gaps, border, rounding, blur, animasi), DND.

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.services

Page {
    onOpened: Hypr.refresh()
    onPoll: Notifications.refresh()

    PageHeader { kicker: "03 · look"; title: "Appearance" }

    // ── Palet ────────────────────────────────────────────────────────
    SectionLabel { text: "palette" }

    InfoRow {
        key: "source"
        value: Theme.walActive ? "pywal  ·  ~/.cache/wal/colors.json" : "default (pywal tidak ditemukan)"
    }

    Flow {
        Layout.fillWidth: true
        spacing: 6
        visible: Theme.palette.length > 0

        Repeater {
            model: Theme.palette
            Rectangle {
                required property string modelData
                width: 26
                height: 26
                radius: Theme.radiusSmall
                color: modelData
                border.color: Theme.border
            }
        }
    }

    Hint { text: "Warna window mengikuti pywal secara live. Ganti wallpaper di halaman Wallpaper untuk membuat palet baru." }

    // ── Hyprland ─────────────────────────────────────────────────────
    SectionLabel { Layout.topMargin: 6; text: "hyprland" }

    Hint {
        visible: !Hypr.ready
        warn: true
        text: "Tidak bisa membaca opsi dari hyprctl."
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: 24
        rowSpacing: 14
        enabled: Hypr.ready

        ValueSlider {
            label: "gaps in"; from: 0; to: 30; suffix: "px"
            value: Hypr.gapsIn
            onMoved: v => Hypr.set("gapsIn", v)
        }
        ValueSlider {
            label: "gaps out"; from: 0; to: 60; suffix: "px"
            value: Hypr.gapsOut
            onMoved: v => Hypr.set("gapsOut", v)
        }
        ValueSlider {
            label: "border"; from: 0; to: 8; suffix: "px"
            value: Hypr.borderSize
            onMoved: v => Hypr.set("borderSize", v)
        }
        ValueSlider {
            label: "rounding"; from: 0; to: 30; suffix: "px"
            value: Hypr.rounding
            onMoved: v => Hypr.set("rounding", v)
        }
    }

    SettingRow {
        Layout.topMargin: 4
        title: "Blur"
        sub: "decoration:blur:enabled"
        enabled: Hypr.ready
        Switch { checked: Hypr.blur; onToggled: Hypr.set("blur", !Hypr.blur) }
    }

    SettingRow {
        title: "Animations"
        sub: "animations:enabled"
        enabled: Hypr.ready
        Switch { checked: Hypr.animations; onToggled: Hypr.set("animations", !Hypr.animations) }
    }

    Hint {
        text: "Diterapkan langsung dan disimpan ke ~/.config/hypr/quickshell.conf. " +
              "Agar bertahan setelah login, tambahkan  source = ~/.config/hypr/quickshell.conf  di akhir hyprland.conf."
    }

    // ── Notifikasi ───────────────────────────────────────────────────
    SectionLabel { Layout.topMargin: 6; text: "notifications" }

    SettingRow {
        icon: Notifications.dnd ? Icons.bellOff : Icons.bell
        title: "Do not disturb"
        sub: Notifications.available ? "via " + Notifications.daemon
                                     : "Tidak ada swaync, mako, atau dunst yang berjalan"
        Switch {
            checked: Notifications.dnd
            enabled: Notifications.available
            onToggled: Notifications.toggle()
        }
    }
}
