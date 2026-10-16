// Bar atas, satu per monitor. Bentuk & isi diambil dari BarState.layout,
// jadi ganti layout = bar langsung berubah tanpa restart.

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

Scope {
    id: root

    signal openPage(string name)
    signal toggleControl()

    readonly property var lay: BarState.layout
    readonly property bool needsStats: BarState.allModules.some(m => m === "cpu" || m === "memory")

    // Polling ringan untuk indikator
    Timer {
        interval: 3000
        repeat: true
        running: BarState.shown
        triggeredOnStart: true
        onTriggered: {
            Audio.refresh();
            Network.refresh();
            Bluetooth.refresh();
            Battery.refresh();
            Brightness.refresh();
            Notifications.refresh();
            PowerProfile.refresh();
            if (root.needsStats) SystemStats.refresh();
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData

            screen: modelData
            visible: BarState.shown
            anchors { top: true; left: true; right: true }
            margins {
                top: root.lay.margin?.top ?? 0
                left: root.lay.margin?.left ?? 0
                right: root.lay.margin?.right ?? 0
            }
            implicitHeight: root.lay.height
            color: "transparent"
            WlrLayershell.namespace: "quickshell-bar"

            // ── Latar (gaya "solid") ─────────────────────────────────
            Rectangle {
                anchors.fill: parent
                visible: root.lay.style === "solid"
                color: Theme.bg
                radius: root.lay.radius
                border.width: root.lay.radius > 0 ? 1 : 0
                border.color: Theme.border

                // flatTop: tutup sudut atas supaya hanya sudut bawah yang membulat
                Rectangle {
                    visible: root.lay.flatTop === true && root.lay.radius > 0
                    width: parent.width
                    height: parent.radius
                    color: Theme.bg
                }
            }

            // Garis bawah untuk bar solid tanpa radius
            Rectangle {
                visible: root.lay.style === "solid" && root.lay.radius === 0
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Theme.border
            }

            // ── Kiri / tengah / kanan ────────────────────────────────
            Section {
                anchors.left: parent.left
                anchors.leftMargin: root.lay.style === "solid" ? 6 : 0
                anchors.verticalCenter: parent.verticalCenter
                specs: root.lay.left
                monitor: win.modelData
                window: win
                layout: root.lay
                onOpenPage: n => root.openPage(n)
                onToggleControl: root.toggleControl()
            }

            Section {
                anchors.centerIn: parent
                visible: !(Config.islandEnabled && root.lay.island === true)
                specs: root.lay.center
                monitor: win.modelData
                window: win
                layout: root.lay
                onOpenPage: n => root.openPage(n)
                onToggleControl: root.toggleControl()
            }

            Section {
                anchors.right: parent.right
                anchors.rightMargin: root.lay.style === "solid" ? 6 : 0
                anchors.verticalCenter: parent.verticalCenter
                specs: root.lay.right
                monitor: win.modelData
                window: win
                layout: root.lay
                onOpenPage: n => root.openPage(n)
                onToggleControl: root.toggleControl()
            }
        }
    }
}
