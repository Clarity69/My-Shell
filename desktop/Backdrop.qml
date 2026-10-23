// Wallpaper for external screens, drawn by Quickshell itself.
// awww-daemon sometimes never picks up a hotplugged output (e.g. a VGA TV), leaving it black.
// awww keeps handling the laptop panel; every other screen gets the same image here.
// The path comes from ~/.cache/wal/wal, which pywal rewrites on every wallpaper change.

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.services

Scope {
    id: root

    // pywal's record of the current wallpaper, falling back to what awww reports
    property string walImage: ""
    readonly property string image: walImage !== "" ? walImage : Wallpaper.current

    FileView {
        path: Config.home + "/.cache/wal/wal"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.walImage = text().trim()
    }

    Component.onCompleted: Wallpaper.refresh()

    Variants {
        // Every screen except the laptop panel
        model: Quickshell.screens.filter(s => !/^(eDP|LVDS|DSI)/.test(s.name))

        PanelWindow {
            required property var modelData

            screen: modelData
            visible: Config.backdropExternal
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "quickshell-backdrop"
            color: Theme.bg

            Image {
                id: current
                anchors.fill: parent
                source: root.image !== "" ? "file://" + root.image : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                sourceSize.width: parent.width
                sourceSize.height: parent.height
                opacity: status === Image.Ready ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 500 } }
            }
        }
    }
}
