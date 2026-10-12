// System tray (StatusNotifierItem): Discord, Steam, nm-applet, dll.
// Klik kiri = aktifkan aplikasi, klik kanan = menu aplikasi.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs.config

RowLayout {
    id: root

    required property var window     // PanelWindow tempat menu ditampilkan

    spacing: 10

    Repeater {
        model: SystemTray.items

        MouseArea {
            id: item
            required property var modelData

            implicitWidth: 16
            implicitHeight: 16
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor

            IconImage {
                anchors.fill: parent
                source: item.modelData.icon
            }

            onClicked: mouse => {
                if (mouse.button === Qt.LeftButton && !item.modelData.onlyMenu) {
                    item.modelData.activate();
                } else if (item.modelData.hasMenu) {
                    const p = item.mapToItem(null, 0, item.height + 6);
                    item.modelData.display(root.window, p.x, p.y);
                }
            }
        }
    }
}
