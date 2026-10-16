// Jam desktop gaya "dossier" (layer Bottom: di atas wallpaper, di bawah window).
//
//   SELAMAT SORE, TAROQ
//   15:35                     <- serif besar
//   Jumat, 17 Oktober 2026
//   ☁ 29° Berawan · Bekasi
//   ─────────────
//   CPU ▂▃▅ 12%   RAM 41%   TEMP 52°   UP 3h 12m
//
//   klik kanan : buka halaman Widgets di Control Center (lewat IPC)

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.bar

PanelWindow {
    id: root

    readonly property bool card: WidgetSettings.clockCard
    readonly property var dayNames: ["Minggu", "Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu"]
    readonly property var monthNames: ["Januari", "Februari", "Maret", "April", "Mei", "Juni",
                                       "Juli", "Agustus", "September", "Oktober", "November", "Desember"]

    readonly property date now: clock.date
    readonly property string greeting: {
        const h = now.getHours();
        if (h < 4)  return "selamat malam";
        if (h < 11) return "selamat pagi";
        if (h < 15) return "selamat siang";
        if (h < 18) return "selamat sore";
        return "selamat malam";
    }

    SystemClock {
        id: clock
        precision: WidgetSettings.clockSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    // Statistik hanya diambil selama widget tampil
    Timer {
        interval: 3000
        repeat: true
        running: root.visible && WidgetSettings.clockStats
        triggeredOnStart: true
        onTriggered: SystemStats.refresh()
    }
    Timer {
        interval: 60000
        repeat: true
        running: root.visible && WidgetSettings.clockStats
        triggeredOnStart: true
        onTriggered: SystemInfo.refresh()
    }

    screen: Quickshell.screens.find(s => s.name === WidgetSettings.clockScreen) ?? Quickshell.screens[0]
    visible: WidgetSettings.clockShown

    anchors {
        bottom: WidgetSettings.clockPosition.startsWith("bottom")
        top: WidgetSettings.clockPosition.startsWith("top")
        left: WidgetSettings.clockPosition.endsWith("left")
        right: WidgetSettings.clockPosition.endsWith("right")
    }
    margins {
        top: Config.githubMargin + (BarState.shown ? BarState.layout.height + (BarState.layout.margin?.top ?? 0) : 0)
        bottom: Config.githubMargin
        left: Config.githubMargin
        right: Config.githubMargin
    }

    implicitWidth: box.implicitWidth
    implicitHeight: box.implicitHeight
    color: "transparent"

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "quickshell-clock"

    readonly property bool alignRight: WidgetSettings.clockPosition.endsWith("right")
    readonly property int textAlign: alignRight ? Text.AlignRight : Text.AlignLeft

    Rectangle {
        id: box
        implicitWidth: col.implicitWidth + (root.card ? 44 : 8)
        implicitHeight: col.implicitHeight + (root.card ? 36 : 8)
        radius: Theme.radius
        color: root.card ? Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, WidgetSettings.clockOpacity) : "transparent"
        border.width: root.card ? 1 : 0
        border.color: Theme.border

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            onClicked: Quickshell.execDetached(["quickshell", "-c", "shell", "ipc", "call", "controlcenter", "open", "widgets"])
        }

        ColumnLayout {
            id: col
            anchors.centerIn: parent
            spacing: 2

            // Tanpa kartu: bayangan halus supaya tetap terbaca di wallpaper terang
            layer.enabled: !root.card
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "#000000"
                shadowOpacity: 0.55
                shadowBlur: 0.7
                shadowVerticalOffset: 2
                shadowHorizontalOffset: 0
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: root.textAlign
                text: (root.greeting + ", " + SystemInfo.user).toUpperCase()
                color: Theme.subtext
                font.family: Theme.font
                font.pixelSize: 11
                font.letterSpacing: 2.5
            }

            // Jam besar
            Row {
                Layout.alignment: root.alignRight ? Qt.AlignRight : Qt.AlignLeft
                spacing: 6

                Text {
                    id: timeText
                    text: Qt.formatDateTime(root.now, "hh:mm")
                    color: Theme.text
                    font.family: Theme.serif
                    font.pixelSize: WidgetSettings.clockSize
                    lineHeight: 0.9
                }
                Text {
                    visible: WidgetSettings.clockSeconds
                    anchors.baseline: timeText.baseline
                    text: Qt.formatDateTime(root.now, "ss")
                    color: Theme.rose
                    font.family: Theme.serif
                    font.pixelSize: WidgetSettings.clockSize * 0.35
                }
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: root.textAlign
                text: root.dayNames[root.now.getDay()] + ", " + root.now.getDate() + " "
                      + root.monthNames[root.now.getMonth()] + " " + root.now.getFullYear()
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 1
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: root.textAlign
                visible: Config.weatherEnabled && Weather.available
                text: Weather.icon + "  " + Math.round(Weather.temp) + "°  " + Weather.description
                      + (Weather.city !== "" ? "  ·  " + Weather.city : "")
                color: Theme.subtext
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 1
            }

            // ── Statistik sistem ─────────────────────────────────────
            Rectangle {
                visible: WidgetSettings.clockStats
                Layout.topMargin: 10
                Layout.bottomMargin: 6
                Layout.alignment: root.alignRight ? Qt.AlignRight : Qt.AlignLeft
                implicitWidth: 40
                implicitHeight: 2
                color: Theme.rose
            }

            RowLayout {
                visible: WidgetSettings.clockStats
                Layout.alignment: root.alignRight ? Qt.AlignRight : Qt.AlignLeft
                spacing: 18

                Stat { label: "CPU"; value: Math.round(SystemStats.cpu * 100) + "%"; ratio: SystemStats.cpu }
                Stat { label: "RAM"; value: Math.round(SystemStats.mem * 100) + "%"; ratio: SystemStats.mem }
                Stat {
                    visible: SystemStats.temp > 0
                    label: "TEMP"; value: SystemStats.temp + "°"
                    ratio: Math.min(1, SystemStats.temp / 100)
                    hot: SystemStats.temp >= 80
                }
                Stat { visible: SystemInfo.uptime !== ""; label: "UP"; value: SystemInfo.uptime; ratio: -1 }
            }
        }
    }

    // Satu angka kecil: label + nilai + bar tipis
    component Stat: ColumnLayout {
        id: stat
        property string label: ""
        property string value: ""
        property real ratio: 0        // -1 = tanpa bar
        property bool hot: false
        spacing: 3

        Text {
            text: stat.label
            color: Theme.muted
            font.family: Theme.font
            font.pixelSize: 9
            font.letterSpacing: 1.5
        }
        Text {
            text: stat.value
            color: stat.hot ? Theme.danger : Theme.text
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
        }
        Rectangle {
            visible: stat.ratio >= 0
            implicitWidth: 44
            implicitHeight: 3
            radius: 1.5
            color: Theme.border
            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, stat.ratio))
                height: parent.height
                radius: 1.5
                color: stat.hot ? Theme.danger : Theme.rose
                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
            }
        }
    }
}
