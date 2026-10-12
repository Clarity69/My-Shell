// Desktop widget: tampil/sembunyi, posisi, monitor, gaya. Tersimpan otomatis.

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

    Hint { text: "Widget menempel di atas wallpaper dan di bawah semua window. Pindah ke workspace kosong untuk melihatnya." }

    // ── GitHub ───────────────────────────────────────────────────────
    SectionLabel { Layout.topMargin: 6; text: "github contributions" }

    SettingRow {
        title: "Show widget"
        sub: GitHub.user !== "" ? "@" + GitHub.user + "  ·  " + GitHub.total + " contributions"
                                : "Belum ada data"
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

        // Posisi
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

        // Ukuran & gaya
        ValueSlider {
            label: "cell size"
            from: 7; to: 16; suffix: "px"
            value: WidgetSettings.githubCell
            onMoved: v => WidgetSettings.githubCell = v
        }

        SettingRow {
            title: "Card background"
            sub: "Kartu latar di belakang grafik"
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
}
