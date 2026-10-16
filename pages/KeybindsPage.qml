// Hyprland keybinds (hyprctl binds -j) with a filter.

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.services

Page {
    id: root

    pollInterval: 0
    onOpened: Keybinds.refresh()

    readonly property var shown: {
        const q = filter.text.trim().toLowerCase();
        if (q === "") return Keybinds.binds;
        return Keybinds.binds.filter(b =>
            (b.keys.join(" ") + " " + b.desc + " " + b.submap).toLowerCase().includes(q));
    }

    PageHeader { kicker: "04 · system"; title: "Keybinds" }

    InputField {
        id: filter
        icon: Icons.search
        placeholder: "Filter: super, workspace, exec…"
    }

    SectionLabel { text: root.shown.length + " / " + Keybinds.binds.length + " binds" }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        Repeater {
            model: root.shown

            RowLayout {
                id: bind
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                spacing: 12

                // Keys drawn as "keycaps"
                Row {
                    Layout.preferredWidth: 200
                    spacing: 4

                    Repeater {
                        model: bind.modelData.keys
                        Rectangle {
                            required property string modelData
                            width: cap.implicitWidth + 12
                            height: 20
                            radius: 3
                            color: Theme.surface
                            border.color: Theme.border

                            Text {
                                id: cap
                                anchors.centerIn: parent
                                text: modelData
                                color: Theme.text
                                font.family: Theme.font
                                font.pixelSize: 10
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: (bind.modelData.submap !== "" ? "[" + bind.modelData.submap + "] " : "") + bind.modelData.desc
                    color: Theme.subtext
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 2
                    elide: Text.ElideRight
                }
            }
        }
    }
}
