// System tray (StatusNotifierItem): Discord, OBS, Steam, nm-applet, dll.
//   klik kiri   = buka aplikasi (kalau item cuma punya menu, menu yang dibuka)
//   klik kanan  = menu aplikasi
//   klik tengah = aksi sekunder (tergantung aplikasi)
//   scroll      = diteruskan ke aplikasi (mis. volume di beberapa applet)

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs.config

RowLayout {
    id: root

    required property var window     // PanelWindow bar, tempat menu ditempel

    spacing: 8

    Repeater {
        model: SystemTray.items

        MouseArea {
            id: item
            required property SystemTrayItem modelData

            implicitWidth: 16
            implicitHeight: 16
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            cursorShape: Qt.PointingHandCursor

            function openMenu() {
                if (!modelData.hasMenu) return;
                // Posisi menu: tepat di bawah ikon, relatif ke window bar
                const p = item.mapToItem(null, 0, 0);
                menu.anchor.rect.x = p.x;
                menu.anchor.rect.y = p.y;
                menu.anchor.rect.width = item.width;
                menu.anchor.rect.height = item.height + 6;
                menu.open();
            }

            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) openMenu();
                else if (mouse.button === Qt.MiddleButton) modelData.secondaryActivate();
                else if (modelData.onlyMenu) openMenu();
                else modelData.activate();
            }

            onWheel: wheel => {
                const horizontal = Math.abs(wheel.angleDelta.x) > Math.abs(wheel.angleDelta.y);
                modelData.scroll(horizontal ? wheel.angleDelta.x : wheel.angleDelta.y, horizontal);
            }

            // Menu bawaan aplikasi, dirender Quickshell sebagai popup di bawah ikon
            QsMenuAnchor {
                id: menu
                menu: item.modelData.menu
                anchor.window: root.window
                anchor.edges: Edges.Bottom | Edges.Left
                anchor.gravity: Edges.Bottom | Edges.Right
            }

            IconImage {
                anchors.fill: parent
                source: item.modelData.icon
            }
        }
    }
}
