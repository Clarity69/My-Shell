// Riwayat clipboard (cliphist). Klik = salin lagi, ikon tong sampah = hapus.

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.services

Page {
    id: root

    pollInterval: 3000
    onOpened: Clipboard.refresh()
    onPoll: Clipboard.refresh()

    readonly property var shown: {
        const q = filter.text.trim().toLowerCase();
        if (q === "") return Clipboard.items;
        return Clipboard.items.filter(i => (i.image ? "image " + i.meta : i.text).toLowerCase().includes(q));
    }

    PageHeader { kicker: "04 · system"; title: "Clipboard" }

    Hint {
        visible: !Clipboard.available && !Clipboard.loading
        warn: true
        text: "cliphist tidak ditemukan. Pasang cliphist + wl-clipboard dan tambahkan di hyprland.conf:\n" +
              "exec-once = wl-paste --type text --watch cliphist store\n" +
              "exec-once = wl-paste --type image --watch cliphist store"
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        visible: Clipboard.available

        InputField {
            id: filter
            icon: Icons.search
            placeholder: "Filter riwayat…"
        }
        TextButton {
            text: "Clear all"
            enabled: Clipboard.items.length > 0
            onClicked: Clipboard.wipe()
        }
    }

    SectionLabel {
        visible: Clipboard.available
        text: root.shown.length + " / " + Clipboard.items.length + " items"
    }

    Hint {
        visible: Clipboard.available && Clipboard.items.length === 0 && !Clipboard.loading
        text: "Riwayat masih kosong. Copy sesuatu, lalu muncul di sini."
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Repeater {
            model: root.shown

            Rectangle {
                id: row
                required property var modelData
                readonly property bool justCopied: Clipboard.copied === modelData.id

                Layout.fillWidth: true
                implicitHeight: modelData.image && modelData.thumb !== "" ? 76 : 40
                radius: Theme.radiusSmall
                color: justCopied ? Theme.surface2 : mouse.containsMouse ? Theme.surface : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Clipboard.copy(row.modelData)
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 6
                    spacing: 12

                    // Thumbnail gambar
                    Rectangle {
                        visible: row.modelData.image && row.modelData.thumb !== ""
                        Layout.preferredWidth: 104
                        Layout.preferredHeight: 60
                        radius: Theme.radiusSmall
                        color: Theme.surface
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: row.modelData.thumb
                            sourceSize.width: 208
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: row.modelData.image ? "image  ·  " + row.modelData.meta
                                                  : row.modelData.text.replace(/\s+/g, " ")
                        color: row.modelData.image ? Theme.subtext : Theme.text
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 1
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                    Text {
                        visible: row.justCopied
                        text: "copied"
                        color: Theme.subtext
                        font.family: Theme.font
                        font.pixelSize: 10
                    }

                    IconButton {
                        icon: Icons.trash
                        size: 28
                        iconColor: Theme.muted
                        opacity: mouse.containsMouse ? 1 : 0.4
                        onClicked: Clipboard.remove(row.modelData)
                    }
                }
            }
        }
    }
}
