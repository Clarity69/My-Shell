// Display: brightness (brightnessctl), night light (hyprsunset), monitor info.

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.services

Page {
    onOpened: Displays.refresh()
    onPoll: {
        Brightness.refresh();
        NightLight.refresh();
        SystemInfo.refresh();
    }

    PageHeader { kicker: "02 · devices"; title: "Display" }

    // ── Brightness ─────────────────────────────────────────────────
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
        text: "No backlight detected (brightnessctl not installed, or an external monitor)."
    }

    // ── Night light ──────────────────────────────────────────────────
    SectionLabel { Layout.topMargin: 6; text: "night light" }

    SettingRow {
        icon: Icons.night
        title: "Night light"
        sub: !NightLight.available ? "hyprsunset not installed"
           : NightLight.active ? "On · " + NightLight.temperature + "K" : "Off"

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

    Hint { text: "Lower is warmer. Applied when you release the slider." }

    // ── External display ─────────────────────────────────────────────
    SectionLabel { Layout.topMargin: 6; text: "external display" }

    InfoRow {
        key: "output"
        value: !Displays.connected ? "not connected"
             : Displays.external.name + "  ·  " + Displays.external.desc
    }

    // Mode: Extend (home) · Mirror (presenting) · Laptop only
    GridLayout {
        Layout.fillWidth: true
        columns: 3
        columnSpacing: 4
        enabled: Displays.connected && !Displays.busy
        opacity: enabled ? 1 : 0.45

        Repeater {
            model: [
                { id: "extend", label: "Extend", sub: "second screen" },
                { id: "mirror", label: "Mirror", sub: "same picture" },
                { id: "off",    label: "Laptop only", sub: "TV off" }
            ]
            ListRow {
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                title: modelData.label
                sub: modelData.sub
                active: Displays.mode === modelData.id
                trailing: Displays.busy && Displays.mode !== modelData.id ? "" : (active ? "active" : "")
                onClicked: Displays.setMode(modelData.id)
            }
        }
    }

    // TV resolution (used by Extend and Mirror)
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6
        visible: Displays.connected && Displays.resolutions.length > 0
        enabled: !Displays.busy

        Text {
            text: "TV RESOLUTION"
            color: Theme.muted
            font.family: Theme.font
            font.pixelSize: 10
            font.letterSpacing: 1.5
        }

        Flow {
            Layout.fillWidth: true
            spacing: 6

            TextButton {
                text: "auto"
                primary: Displays.resolution === "preferred"
                onClicked: Displays.setResolution("preferred")
            }

            Repeater {
                model: Displays.resolutions
                TextButton {
                    required property string modelData
                    readonly property var parts: modelData.split("@")
                    text: parts[0] + " · " + Math.round(parseFloat(parts[1] ?? "0")) + "Hz"
                    primary: Displays.resolution !== "preferred"
                             && Displays.resolution.split("@")[0] === parts[0]
                             && Math.round(parseFloat(Displays.resolution.split("@")[1] ?? "0")) === Math.round(parseFloat(parts[1] ?? "0"))
                    onClicked: Displays.setResolution(modelData)
                }
            }
        }
    }

    Hint {
        text: Displays.busy ? "Applying…"
            : Displays.connected
              ? "Extend for a monitor at home, Mirror for presenting. If the TV stays black or shows no signal, pick a lower resolution. Plugging in again uses the rules in monitors.conf."
              : "Plug in a TV or monitor (VGA, HDMI or mini DP); it shows up here automatically."
    }

    // ── Monitor ──────────────────────────────────────────────────────
    SectionLabel { Layout.topMargin: 6; text: "monitor" }

    InfoRow { key: "resolution"; value: SystemInfo.resolution }
    InfoRow { key: "compositor"; value: SystemInfo.compositor }
}
