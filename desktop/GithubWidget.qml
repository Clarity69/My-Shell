// Grafik kontribusi GitHub di desktop (layer Bottom: di atas wallpaper, di bawah window).
//   hover kotak : jumlah kontribusi di tanggal itu
//   klik        : buka profil GitHub
//   klik kanan  : ambil ulang data

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.bar

PanelWindow {
    id: root

    readonly property int cell: WidgetSettings.githubCell
    readonly property int gap: 3
    readonly property var monthNames: ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                                       "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

    // Kolom per minggu (Minggu di atas, seperti GitHub). Sel kosong = null.
    readonly property var cells: {
        const d = GitHub.days;
        if (d.length === 0) return [];
        const pad = d[0].date.getDay();
        return Array(pad).fill(null).concat(d);
    }
    readonly property int weeks: Math.ceil(cells.length / 7)

    // Label bulan: di kolom yang memuat tanggal 1–7
    readonly property var monthLabels: {
        const out = [];
        let last = -1;
        for (let w = 0; w < weeks; w++) {
            const c = cells.slice(w * 7, w * 7 + 7).find(x => x);
            if (!c) continue;
            const m = c.date.getMonth();
            if (m !== last && c.date.getDate() <= 7) { out.push({ col: w, text: monthNames[m] }); last = m; }
        }
        return out;
    }

    property var hovered: null

    function levelColor(l) {
        if (l <= 0) return Theme.surface2;
        return Theme.mix(Theme.surface2, Theme.rose, [0, 0.35, 0.55, 0.78, 1][l]);
    }

    screen: Quickshell.screens.find(s => s.name === WidgetSettings.githubScreen) ?? Quickshell.screens[0]
    visible: GitHub.shown && GitHub.days.length > 0

    anchors {
        bottom: WidgetSettings.githubPosition.startsWith("bottom")
        top: WidgetSettings.githubPosition.startsWith("top")
        left: WidgetSettings.githubPosition.endsWith("left")
        right: WidgetSettings.githubPosition.endsWith("right")
    }
    margins {
        // jangan menempel ke bar di posisi atas
        top: Config.githubMargin + (BarState.shown ? BarState.layout.height + (BarState.layout.margin?.top ?? 0) : 0)
        bottom: Config.githubMargin
        left: Config.githubMargin
        right: Config.githubMargin
    }

    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight
    color: "transparent"

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "quickshell-github"

    Rectangle {
        id: card
        implicitWidth: col.implicitWidth + 36
        implicitHeight: col.implicitHeight + 32
        radius: Theme.radius
        color: WidgetSettings.githubCard
               ? Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, WidgetSettings.githubOpacity) : "transparent"
        border.width: WidgetSettings.githubCard ? 1 : 0
        border.color: Theme.border

        ColumnLayout {
            id: col
            anchors.centerIn: parent
            spacing: 10

            // ── Header ───────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                ColumnLayout {
                    spacing: 0
                    Text {
                        text: "CONTRIBUTIONS  ·  @" + GitHub.user
                        color: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: 10
                        font.letterSpacing: 1.5
                    }
                    Row {
                        spacing: 8
                        Text {
                            id: totalText
                            text: GitHub.total.toLocaleString(Qt.locale("en_US"), "f", 0)
                            color: Theme.text
                            font.family: Theme.serif
                            font.pixelSize: 34
                        }
                        Text {
                            anchors.baseline: totalText.baseline
                            text: "in the last year"
                            color: Theme.subtext
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 1
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Streak
                Repeater {
                    model: [
                        { label: "current streak", value: GitHub.currentStreak },
                        { label: "longest streak", value: GitHub.longestStreak },
                        { label: "best day", value: GitHub.bestDay ? GitHub.bestDay.count : 0 }
                    ]
                    ColumnLayout {
                        required property var modelData
                        Layout.alignment: Qt.AlignBottom
                        spacing: 0
                        Text {
                            text: modelData.label.toUpperCase()
                            color: Theme.muted
                            font.family: Theme.font
                            font.pixelSize: 9
                            font.letterSpacing: 1.2
                        }
                        Text {
                            text: modelData.value + (modelData.label === "best day" ? "" : "d")
                            color: Theme.text
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize + 3
                        }
                    }
                }
            }

            // ── Label bulan ──────────────────────────────────────────
            Item {
                Layout.leftMargin: 28
                implicitWidth: root.weeks * (root.cell + root.gap)
                implicitHeight: 12

                Repeater {
                    model: root.monthLabels
                    Text {
                        required property var modelData
                        x: modelData.col * (root.cell + root.gap)
                        text: modelData.text
                        color: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: 9
                    }
                }
            }

            // ── Grid ─────────────────────────────────────────────────
            Row {
                spacing: 6

                // Label hari
                Column {
                    width: 22
                    spacing: root.gap
                    Repeater {
                        model: ["", "Mon", "", "Wed", "", "Fri", ""]
                        Text {
                            required property string modelData
                            height: root.cell
                            width: 22
                            verticalAlignment: Text.AlignVCenter
                            text: modelData
                            color: Theme.muted
                            font.family: Theme.font
                            font.pixelSize: 9
                        }
                    }
                }

                Grid {
                    rows: 7
                    flow: Grid.TopToBottom
                    spacing: root.gap

                    Repeater {
                        model: root.cells

                        Rectangle {
                            required property var modelData
                            width: root.cell
                            height: root.cell
                            radius: 2
                            color: modelData ? root.levelColor(modelData.level) : "transparent"
                            border.width: modelData && root.hovered === modelData ? 1 : 0
                            border.color: Theme.text

                            MouseArea {
                                anchors.fill: parent
                                enabled: parent.modelData !== null
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                cursorShape: Qt.PointingHandCursor
                                onEntered: root.hovered = parent.modelData
                                onExited: if (root.hovered === parent.modelData) root.hovered = null
                                onClicked: mouse => mouse.button === Qt.RightButton
                                    ? GitHub.refresh()
                                    : Qt.openUrlExternally("https://github.com/" + GitHub.user)
                            }
                        }
                    }
                }
            }

            // ── Footer ───────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 28

                Text {
                    Layout.fillWidth: true
                    text: root.hovered
                          ? root.hovered.count + " contributions on " + Qt.formatDate(root.hovered.date, "ddd, d MMM yyyy")
                          : GitHub.loading ? "updating…"
                          : GitHub.error !== "" ? GitHub.error
                          : "updated " + Qt.formatTime(GitHub.updated, "hh:mm")
                    color: GitHub.error !== "" && !root.hovered ? Theme.rose : Theme.subtext
                    font.family: Theme.font
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }

                Text {
                    text: "less"
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 9
                }
                Repeater {
                    model: 5
                    Rectangle {
                        required property int index
                        width: root.cell
                        height: root.cell
                        radius: 2
                        color: root.levelColor(index)
                    }
                }
                Text {
                    text: "more"
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 9
                }
            }
        }
    }
}
