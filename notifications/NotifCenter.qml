// Pusat notifikasi yang turun dari bar (pojok kanan atas, monitor yang fokus).
// Buka/tutup: klik lonceng di bar, atau  qs -c shell ipc call notifications toggle
// Tutup juga dengan Esc atau klik di luar panel.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config
import qs.components
import qs.services
import qs.bar

PanelWindow {
    id: root

    readonly property int barOffset: BarState.shown
        ? BarState.layout.height + (BarState.layout.margin?.top ?? 0) : 0
    readonly property int maxHeight: Math.round((screen?.height ?? 900) * 0.75) - barOffset

    property int tick: 0          // menyegarkan label waktu ("5m", "1h") selama terbuka

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    visible: Notifications.centerOpen || panel.opacity > 0

    anchors { top: true; right: true }
    margins {
        top: root.barOffset + Theme.gap
        right: Theme.gap
    }

    implicitWidth: Config.notifWidth + 24
    implicitHeight: Math.min(root.maxHeight, header.implicitHeight + content.implicitHeight + 40)
    color: "transparent"

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notification-center"
    WlrLayershell.keyboardFocus: Notifications.centerOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // Klik di luar panel = tutup
    HyprlandFocusGrab {
        windows: [ root ]
        active: Notifications.centerOpen && root.visible
        onCleared: Notifications.centerOpen = false
    }

    Timer {
        interval: 30000
        repeat: true
        running: Notifications.centerOpen
        onTriggered: root.tick++
    }

    Rectangle {
        id: panel
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.bg
        border.color: Theme.border

        opacity: Notifications.centerOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        transform: Translate {
            y: Notifications.centerOpen ? 0 : -10
            Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }

        Item {
            anchors.fill: parent
            focus: Notifications.centerOpen
            Keys.onEscapePressed: Notifications.centerOpen = false
        }

        // ── Header ───────────────────────────────────────────────────
        ColumnLayout {
            id: header
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text {
                        text: "NOTIFICATIONS"
                        color: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: 10
                        font.letterSpacing: 1.5
                    }
                    Text {
                        text: Notifications.count > 0 ? Notifications.count + " New" : "All done"
                        color: Theme.text
                        font.family: Theme.serif
                        font.pixelSize: 22
                    }
                }

                TextButton {
                    text: "Clear all"
                    enabled: Notifications.count > 0
                    onClicked: Notifications.clearAll()
                }
            }

            SettingRow {
                icon: Notifications.dnd ? Icons.bellOff : Icons.bell
                title: "Do not disturb"
                sub: Notifications.dnd ? "Popup Hidden" : "Popup Show"
                Switch { checked: Notifications.dnd; onToggled: Notifications.toggle() }
            }

            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.border }
        }

        // ── Daftar ───────────────────────────────────────────────────
        Flickable {
            id: flick
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.bottom: parent.bottom
            anchors.margins: 8
            anchors.topMargin: 4
            contentHeight: content.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            ColumnLayout {
                id: content
                width: flick.width
                spacing: 2

                Text {
                    visible: Notifications.count === 0
                    Layout.fillWidth: true
                    Layout.topMargin: 24
                    Layout.bottomMargin: 24
                    horizontalAlignment: Text.AlignHCenter
                    text: "All clear"
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 1
                }

                Repeater {
                    model: Notifications.groups

                    ColumnLayout {
                        id: group
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: 6
                            Layout.leftMargin: 6

                            Text {
                                Layout.fillWidth: true
                                text: group.modelData.app + "  ·  " + group.modelData.items.length
                                color: Theme.subtext
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 2
                                font.bold: true
                            }
                            TextButton {
                                text: "Clear"
                                onClicked: group.modelData.items.slice().forEach(n => Notifications.dismiss(n))
                            }
                        }

                        Repeater {
                            model: group.modelData.items

                            NotifCard {
                                required property var modelData
                                Layout.fillWidth: true
                                compact: true
                                notif: modelData
                                refreshTick: root.tick
                            }
                        }
                    }
                }
            }
        }

        // Indikator scroll
        Rectangle {
            visible: flick.contentHeight > flick.height
            anchors.right: parent.right
            anchors.rightMargin: 3
            width: 3
            radius: 1.5
            color: Theme.surface2
            height: Math.max(24, flick.height * flick.height / Math.max(1, flick.contentHeight))
            y: flick.y + flick.contentY / Math.max(1, flick.contentHeight - flick.height) * (flick.height - height)
        }
    }
}
