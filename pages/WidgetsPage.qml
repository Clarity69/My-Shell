// Desktop widgets: show/hide, position, monitor, style. Saved automatically.

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.components
import qs.services

Page {
    id: root

    pollInterval: 0

    readonly property var positions: [
        { id: "top-left", label: "Top left" },
        { id: "top-right", label: "Top right" },
        { id: "bottom-left", label: "Bottom left" },
        { id: "bottom-right", label: "Bottom right" }
    ]

    PageHeader { kicker: "03 · look"; title: "Widgets" }

    Hint { text: "Widgets sit above the wallpaper and below all windows. Switch to an empty workspace to see them." }

    // ── GitHub ───────────────────────────────────────────────────────
    SectionLabel { Layout.topMargin: 6; text: "github contributions" }

    SettingRow {
        title: "Show widget"
        sub: GitHub.user !== "" ? "@" + GitHub.user + "  ·  " + GitHub.total + " contributions"
                                : "No data yet"
        Switch {
            checked: WidgetSettings.githubShown
            onToggled: WidgetSettings.githubShown = !WidgetSettings.githubShown
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 14
        enabled: WidgetSettings.githubShown
        opacity: enabled ? 1 : 0.45

        // Position
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "POSITION"
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 10
                font.letterSpacing: 1.5
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 4
                rowSpacing: 2

                Repeater {
                    model: root.positions
                    ListRow {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        title: modelData.label
                        trailing: WidgetSettings.githubPosition === modelData.id ? "active" : ""
                        active: WidgetSettings.githubPosition === modelData.id
                        onClicked: WidgetSettings.githubPosition = modelData.id
                    }
                }
            }
        }

        // Monitor
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: Quickshell.screens.length > 1

            Text {
                text: "MONITOR"
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 10
                font.letterSpacing: 1.5
            }

            Flow {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: Quickshell.screens
                    TextButton {
                        required property var modelData
                        required property int index
                        readonly property bool current: WidgetSettings.githubScreen === modelData.name
                            || (WidgetSettings.githubScreen === "" && index === 0)
                        text: modelData.name + "  " + modelData.width + "×" + modelData.height
                        primary: current
                        onClicked: WidgetSettings.githubScreen = modelData.name
                    }
                }
            }
        }

        // Size & style
        ValueSlider {
            label: "cell size"
            from: 7; to: 16; suffix: "px"
            value: WidgetSettings.githubCell
            onMoved: v => WidgetSettings.githubCell = v
        }

        SettingRow {
            title: "Card background"
            sub: "Background card behind the graph"
            Switch {
                checked: WidgetSettings.githubCard
                onToggled: WidgetSettings.githubCard = !WidgetSettings.githubCard
            }
        }

        ValueSlider {
            visible: WidgetSettings.githubCard
            label: "card opacity"
            from: 30; to: 100; suffix: "%"
            value: Math.round(WidgetSettings.githubOpacity * 100)
            onMoved: v => WidgetSettings.githubOpacity = v / 100
        }
    }

    // Data
    InfoRow { key: "account"; value: GitHub.user !== "" ? "@" + GitHub.user : "" }
    InfoRow {
        key: "updated"
        value: GitHub.loading ? "updating…"
             : GitHub.error !== "" ? GitHub.error
             : GitHub.days.length > 0 ? Qt.formatTime(GitHub.updated, "hh:mm") : ""
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Item { Layout.fillWidth: true }
        TextButton { text: "Reset"; onClicked: WidgetSettings.reset() }
        TextButton {
            primary: true
            text: GitHub.loading ? "Updating…" : "Refresh data"
            enabled: !GitHub.loading
            onClicked: GitHub.refresh()
        }
    }

    // ── Desktop clock ───────────────────────────────────────────────
    SectionLabel { Layout.topMargin: 18; text: "desktop clock" }

    SettingRow {
        title: "Show widget"
        sub: "Time, date, weather, and system stats"
        Switch {
            checked: WidgetSettings.clockShown
            onToggled: WidgetSettings.clockShown = !WidgetSettings.clockShown
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 14
        enabled: WidgetSettings.clockShown
        opacity: enabled ? 1 : 0.45

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "POSITION"
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 10
                font.letterSpacing: 1.5
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 4
                rowSpacing: 2

                Repeater {
                    model: root.positions
                    ListRow {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        title: modelData.label
                        trailing: WidgetSettings.clockPosition === modelData.id ? "active" : ""
                        active: WidgetSettings.clockPosition === modelData.id
                        onClicked: WidgetSettings.clockPosition = modelData.id
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: Quickshell.screens.length > 1

            Text {
                text: "MONITOR"
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 10
                font.letterSpacing: 1.5
            }

            Flow {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: Quickshell.screens
                    TextButton {
                        required property var modelData
                        required property int index
                        readonly property bool current: WidgetSettings.clockScreen === modelData.name
                            || (WidgetSettings.clockScreen === "" && index === 0)
                        text: modelData.name + "  " + modelData.width + "×" + modelData.height
                        primary: current
                        onClicked: WidgetSettings.clockScreen = modelData.name
                    }
                }
            }
        }

        ValueSlider {
            label: "clock size"
            from: 48; to: 140; suffix: "px"
            value: WidgetSettings.clockSize
            onMoved: v => WidgetSettings.clockSize = v
        }

        SettingRow {
            title: "Seconds"
            sub: "Small seconds next to the time"
            Switch {
                checked: WidgetSettings.clockSeconds
                onToggled: WidgetSettings.clockSeconds = !WidgetSettings.clockSeconds
            }
        }

        SettingRow {
            title: "System stats"
            sub: "CPU, RAM, temperature, and uptime under the clock"
            Switch {
                checked: WidgetSettings.clockStats
                onToggled: WidgetSettings.clockStats = !WidgetSettings.clockStats
            }
        }

        SettingRow {
            title: "Card background"
            sub: "Off = text sits right on the wallpaper (with a shadow)"
            Switch {
                checked: WidgetSettings.clockCard
                onToggled: WidgetSettings.clockCard = !WidgetSettings.clockCard
            }
        }

        ValueSlider {
            visible: WidgetSettings.clockCard
            label: "card opacity"
            from: 30; to: 100; suffix: "%"
            value: Math.round(WidgetSettings.clockOpacity * 100)
            onMoved: v => WidgetSettings.clockOpacity = v / 100
        }
    }
}
