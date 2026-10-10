// Kalender bulan kecil (popup di bawah jam).
// Minggu dimulai Senin. Scroll / tombol ‹ › = ganti bulan, klik judul = kembali ke bulan ini.

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config

PopupWindow {
    id: popup

    required property var barWindow     // PanelWindow bar
    required property Item target       // item jam yang dijadikan patokan posisi

    readonly property bool hovered: hover.hovered

    property date today: new Date()
    property int year: today.getFullYear()
    property int month: today.getMonth()       // 0..11

    readonly property var dayNames: ["Sen", "Sel", "Rab", "Kam", "Jum", "Sab", "Min"]
    readonly property var monthNames: ["Januari", "Februari", "Maret", "April", "Mei", "Juni",
                                       "Juli", "Agustus", "September", "Oktober", "November", "Desember"]

    // 42 sel (6 minggu): { day, current (bulan ini), today }
    readonly property var cells: {
        const first = new Date(year, month, 1);
        const offset = (first.getDay() + 6) % 7;            // Senin = 0
        const start = new Date(year, month, 1 - offset);
        const out = [];
        for (let i = 0; i < 42; i++) {
            const d = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i);
            out.push({
                day: d.getDate(),
                current: d.getMonth() === month,
                today: d.toDateString() === today.toDateString()
            });
        }
        return out;
    }

    function shift(n) {
        const d = new Date(year, month + n, 1);
        year = d.getFullYear();
        month = d.getMonth();
    }

    function resetMonth() {
        today = new Date();
        year = today.getFullYear();
        month = today.getMonth();
    }

    function place() {
        const p = target.mapToItem(null, target.width / 2, target.height);
        const x = Math.round(p.x - implicitWidth / 2);
        anchor.rect.x = Math.max(4, Math.min(x, barWindow.width - implicitWidth - 4));
        anchor.rect.y = Math.round(p.y + 6);
    }

    anchor.window: barWindow
    implicitWidth: 248
    implicitHeight: body.implicitHeight + 24
    color: "transparent"

    onVisibleChanged: if (visible) { resetMonth(); place(); }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.bg
        border.color: Theme.border

        HoverHandler { id: hover }

        WheelHandler {
            onWheel: event => popup.shift(event.angleDelta.y > 0 ? -1 : 1)
        }

        ColumnLayout {
            id: body
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            // Judul + navigasi
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "‹"
                    color: Theme.subtext
                    font.family: Theme.font
                    font.pixelSize: 18
                    MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: popup.shift(-1) }
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: popup.monthNames[popup.month] + " " + popup.year
                    color: Theme.text
                    font.family: Theme.serif
                    font.pixelSize: Theme.fontSize + 3
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: popup.resetMonth() }
                }

                Text {
                    text: "›"
                    color: Theme.subtext
                    font.family: Theme.font
                    font.pixelSize: 18
                    MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: popup.shift(1) }
                }
            }

            // Nama hari
            GridLayout {
                Layout.fillWidth: true
                columns: 7
                columnSpacing: 0
                rowSpacing: 2

                Repeater {
                    model: popup.dayNames
                    Text {
                        required property string modelData
                        required property int index
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        color: index >= 5 ? Theme.rose : Theme.muted
                        font.family: Theme.font
                        font.pixelSize: 10
                    }
                }

                // Tanggal
                Repeater {
                    model: popup.cells
                    Rectangle {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28
                        radius: Theme.radiusSmall
                        color: modelData.today ? Theme.accent : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: modelData.day
                            color: modelData.today ? Theme.accentFg
                                 : !modelData.current ? Theme.muted
                                 : index % 7 >= 5 ? Theme.rose : Theme.text
                            opacity: modelData.current ? 1 : 0.5
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 1
                            font.bold: modelData.today
                        }
                    }
                }
            }

            // Tanggal lengkap hari ini
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: Qt.formatDate(popup.today, "dddd, d MMMM yyyy")
                color: Theme.subtext
                font.family: Theme.font
                font.pixelSize: 10
            }
        }
    }
}
