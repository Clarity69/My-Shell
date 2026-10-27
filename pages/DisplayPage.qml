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

    // Schedule
    SettingRow {
        icon: Icons.night
        title: "Schedule"
        sub: NightLight.scheduled
             ? "On at " + NightLight.onTime + "  ·  off at " + NightLight.offTime
             : "Turn on and off automatically"

        Switch {
            checked: NightLight.scheduled
            enabled: NightLight.available
            onToggled: NightLight.setScheduled(!NightLight.scheduled)
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.gap
        visible: NightLight.scheduled
        enabled: NightLight.available

        TimeStepper {
            label: "turn on"
            minutes: NightLight.onMinutes
            onPicked: m => NightLight.setOn(m)
        }
        TimeStepper {
            label: "turn off"
            minutes: NightLight.offMinutes
            onPicked: m => NightLight.setOff(m)
        }
    }

    Hint {
        visible: NightLight.scheduled
        text: "Click ‹ › or scroll to change by 15 minutes. You can still toggle night light by hand; the schedule takes over again at the next switch time."
    }

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

    // Time picker card: ‹ HH:MM ›, scroll or click to move by 15 minutes
    component TimeStepper: Rectangle {
        id: stepper
        property string label: ""
        property int minutes: 0
        signal picked(int m)

        function step(d) { stepper.picked(((minutes + d * 15) % 1440 + 1440) % 1440); }

        Layout.fillWidth: true
        Layout.preferredWidth: 1
        implicitHeight: 76
        radius: Theme.radius
        color: Theme.surface
        border.width: 1
        border.color: Theme.border

        Text {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: 10
            text: stepper.label.toUpperCase()
            color: Theme.muted
            font.family: Theme.font
            font.pixelSize: 9
            font.letterSpacing: 1.5
        }

        RowLayout {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 6
            spacing: 14

            Text {
                text: "‹"
                color: Theme.subtext
                font.family: Theme.font
                font.pixelSize: 22
                MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; onClicked: stepper.step(-1) }
            }
            Text {
                text: String(Math.floor(stepper.minutes / 60)).padStart(2, "0") + ":" + String(stepper.minutes % 60).padStart(2, "0")
                color: Theme.text
                font.family: Theme.serif
                font.pixelSize: 28
            }
            Text {
                text: "›"
                color: Theme.subtext
                font.family: Theme.font
                font.pixelSize: 22
                MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; onClicked: stepper.step(1) }
            }
        }

        WheelHandler {
            onWheel: event => stepper.step(event.angleDelta.y > 0 ? 1 : -1)
        }
    }
}
