// Layar: kecerahan (brightnessctl), night light (hyprsunset), info monitor.

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.services

Page {
    onPoll: {
        Brightness.refresh();
        NightLight.refresh();
        SystemInfo.refresh();
    }

    PageHeader { kicker: "02 · devices"; title: "Display" }

    // ── Kecerahan ────────────────────────────────────────────────────
    SectionLabel { text: "brightness" }

    SliderRow {
        Layout.fillWidth: true
        visible: Brightness.available
        icon: Icons.brightness
        value: Brightness.value
        onMoved: v => Brightness.setValue(v)
    }

    Hint {
        visible: !Brightness.available
        text: "Tidak ada backlight terdeteksi (brightnessctl tidak terpasang atau monitor eksternal)."
    }

    // ── Night light ──────────────────────────────────────────────────
    SectionLabel { Layout.topMargin: 6; text: "night light" }

    SettingRow {
        icon: Icons.night
        title: "Night light"
        sub: !NightLight.available ? "hyprsunset tidak terpasang"
           : NightLight.active ? "Aktif · " + NightLight.temperature + "K" : "Off"

        Switch {
            checked: NightLight.active
            enabled: NightLight.available
            onToggled: NightLight.toggle()
        }
    }

    ValueSlider {
        enabled: NightLight.available
        label: "temperature"
        from: 2500
        to: 6500
        step: 100
        suffix: "K"
        value: NightLight.temperature
        onCommitted: v => NightLight.setTemperature(v)
    }

    Hint { text: "Makin kecil makin hangat. Suhu diterapkan saat slider dilepas." }

    // ── Monitor ──────────────────────────────────────────────────────
    SectionLabel { Layout.topMargin: 6; text: "monitor" }

    InfoRow { key: "resolution"; value: SystemInfo.resolution }
    InfoRow { key: "compositor"; value: SystemInfo.compositor }
}
