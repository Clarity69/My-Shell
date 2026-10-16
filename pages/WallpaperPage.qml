// Wallpaper: thumbnail grid from Config.wallpaperDir. Click = run your wallpaper script.

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.services

Page {
    id: root

    signal closeRequested()

    pollInterval: 0
    onOpened: Wallpaper.refresh()

    readonly property int columns: 3
    readonly property real tileW: (innerWidth - (columns - 1) * Theme.gap) / columns

    PageHeader { kicker: "03 · look"; title: "Wallpaper" }

    InfoRow { key: "current"; value: Wallpaper.current !== "" ? Wallpaper.fileName(Wallpaper.current) : "" }
    InfoRow { key: "folder";  value: Config.wallpaperDir.replace(Config.home, "~") }
    InfoRow { key: "script";  value: Config.wallpaperSet.split(" ")[0].replace(Config.home, "~") }

    Hint {
        visible: Wallpaper.error !== ""
        warn: true
        text: Wallpaper.error
    }
    Hint {
        visible: Wallpaper.images.length === 0 && !Wallpaper.loading
        text: "No images in this folder. Change wallpaperDir in config/Config.qml."
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        SectionLabel { text: Wallpaper.images.length + " images" }
        TextButton { text: "Refresh"; onClicked: Wallpaper.refresh() }
        TextButton {
            visible: Wallpaper.hasPicker
            primary: true
            text: "Open picker"
            onClicked: { Wallpaper.openPicker(); root.closeRequested(); }
        }
    }

    Grid {
        Layout.fillWidth: true
        columns: root.columns
        spacing: Theme.gap

        Repeater {
            model: Wallpaper.images

            Rectangle {
                id: tile
                required property string modelData
                readonly property bool current: Wallpaper.current === modelData
                readonly property bool applying: Wallpaper.applying === modelData

                width: root.tileW
                height: Math.round(root.tileW * 0.625)
                radius: Theme.radiusSmall
                color: Theme.surface
                clip: true

                Image {
                    anchors.fill: parent
                    anchors.margins: 1
                    source: "file://" + tile.modelData
                    sourceSize.width: 360
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    opacity: tile.applying ? 0.4 : 1
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                // Border: thick = current wallpaper
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.width: tile.current ? 2 : 1
                    border.color: tile.current ? Theme.accent
                                : mouse.containsMouse ? Theme.subtext : Theme.border
                }

                Text {
                    anchors.centerIn: parent
                    visible: tile.applying
                    text: "applying…"
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 2
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Wallpaper.set(tile.modelData)
                }
            }
        }
    }
}
