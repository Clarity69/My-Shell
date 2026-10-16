// Sound (wpctl): volume & output devices, microphone & input devices.

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.services

Page {
    onPoll: Audio.refresh()

    PageHeader { kicker: "02 · devices"; title: "Sound" }

    // ── Output ───────────────────────────────────────────────────────
    SectionLabel { text: "output" }

    SliderRow {
        Layout.fillWidth: true
        icon: Audio.muted ? Icons.volumeOff : Icons.volume
        value: Audio.volume
        dimmed: Audio.muted
        onMoved: v => Audio.setVolume(v)
        onIconClicked: Audio.toggleMute()
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Repeater {
            model: Audio.sinks
            ListRow {
                required property var modelData
                icon: Icons.speaker
                title: modelData.name
                trailing: modelData.isDefault ? "default" : ""
                active: modelData.isDefault
                onClicked: Audio.setDefault(modelData, true)
            }
        }
    }

    // ── Input ────────────────────────────────────────────────────────
    SectionLabel { Layout.topMargin: 6; text: "input" }

    SliderRow {
        Layout.fillWidth: true
        visible: Audio.hasMic
        icon: Audio.micMuted ? Icons.micOff : Icons.mic
        value: Audio.micVolume
        dimmed: Audio.micMuted
        onMoved: v => Audio.setMicVolume(v)
        onIconClicked: Audio.toggleMicMute()
    }

    Hint {
        visible: !Audio.hasMic
        text: "No microphone detected."
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Repeater {
            model: Audio.sources
            ListRow {
                required property var modelData
                icon: Icons.mic
                title: modelData.name
                trailing: modelData.isDefault ? "default" : ""
                active: modelData.isDefault
                onClicked: Audio.setDefault(modelData, false)
            }
        }
    }

    Hint { text: "Click the icon left of a slider to mute. Click a device to make it the default." }
}
