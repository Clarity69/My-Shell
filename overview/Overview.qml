// Workspace overview layar penuh (seperti Mission Control), satu per monitor.
//   klik window      : fokus ke window itu
//   seret window     : pindahkan ke workspace lain
//   klik tengah      : tutup window
//   klik workspace   : pindah ke workspace itu
//   ← → / 1-9 / Enter: pilih & masuk workspace,  Esc: tutup

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData

            readonly property string monName: modelData.name
            readonly property var mon: OverviewState.monitors[monName] ?? { x: 0, y: 0, w: width, h: height, activeWs: -1 }

            // Workspace yang ditampilkan: milik monitor ini + 1..N yang belum dipakai monitor lain
            readonly property var wsList: {
                const own = new Set();
                const elsewhere = new Set();
                for (const w of Hyprland.workspaces.values) {
                    if (w.id <= 0) continue;
                    if (w.monitor && w.monitor.name === monName) own.add(w.id);
                    else elsewhere.add(w.id);
                }
                for (let i = 1; i <= Config.overviewWorkspaces; i++)
                    if (!elsewhere.has(i)) own.add(i);
                return Array.from(own).sort((a, b) => a - b);
            }

            property int selected: mon.activeWs
            property var dragging: null       // client yang sedang diseret
            property point dragPos: Qt.point(0, 0)

            readonly property int cols: Math.min(wsList.length, Config.overviewColumns)
            readonly property int rows: Math.ceil(wsList.length / Math.max(1, cols))
            readonly property real gap: 24
            readonly property real aspect: mon.w / Math.max(1, mon.h)
            readonly property real tileW: Math.min(
                (width * 0.9 - (cols - 1) * gap) / Math.max(1, cols),
                ((height * 0.8 - (rows - 1) * gap) / Math.max(1, rows) - 26) * aspect)
            readonly property real tileH: tileW / aspect

            screen: modelData
            visible: OverviewState.shown
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-overview"
            // Hanya monitor yang sedang fokus yang menerima keyboard
            readonly property bool focused: Hyprland.focusedMonitor?.name === monName
            WlrLayershell.keyboardFocus: visible && focused ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            onVisibleChanged: if (visible) { selected = mon.activeWs; body.forceActiveFocus(); intro.restart(); }

            function step(d) {
                const i = wsList.indexOf(selected);
                selected = wsList[Math.max(0, Math.min(wsList.length - 1, (i < 0 ? 0 : i) + d))];
            }

            Rectangle {
                id: body
                anchors.fill: parent
                color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.82)
                focus: true

                Keys.onPressed: event => {
                    const k = event.key;
                    if (k === Qt.Key_Escape) OverviewState.close();
                    else if (k === Qt.Key_Left || k === Qt.Key_H) win.step(-1);
                    else if (k === Qt.Key_Right || k === Qt.Key_L) win.step(1);
                    else if (k === Qt.Key_Up || k === Qt.Key_K) win.step(-win.cols);
                    else if (k === Qt.Key_Down || k === Qt.Key_J) win.step(win.cols);
                    else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) OverviewState.goTo(win.selected);
                    else if (k >= Qt.Key_1 && k <= Qt.Key_9) OverviewState.goTo(k - Qt.Key_0);
                    else return;
                    event.accepted = true;
                }

                // Klik area kosong = tutup
                MouseArea {
                    anchors.fill: parent
                    onClicked: OverviewState.close()
                }

                ParallelAnimation {
                    id: intro
                    NumberAnimation { target: grid; property: "opacity"; from: 0; to: 1; duration: 180; easing.type: Easing.OutCubic }
                    NumberAnimation { target: grid; property: "scale"; from: 0.96; to: 1; duration: 220; easing.type: Easing.OutCubic }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 18

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "WORKSPACES  ·  " + win.monName
                        color: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: 11
                        font.letterSpacing: 2
                    }

                    Grid {
                        id: grid
                        Layout.alignment: Qt.AlignHCenter
                        columns: win.cols
                        spacing: win.gap

                        Repeater {
                            id: tiles
                            model: win.wsList

                            WorkspaceTile {
                                required property int modelData
                                ws: modelData
                                tileW: win.tileW
                                tileH: win.tileH
                                mon: win.mon
                                monName: win.monName
                                active: win.mon.activeWs === modelData
                                selected: win.selected === modelData
                                dropTarget: win.dragging !== null && win.hoveredWs === modelData
                                overlay: body
                                onHoveredChanged: if (hovered && win.dragging === null) win.selected = modelData
                                onDragStarted: c => win.dragging = c
                                onDragMoved: p => win.dragPos = p
                                onDragEnded: {
                                    if (win.dragging && win.hoveredWs > 0)
                                        OverviewState.moveWindow(win.dragging, win.hoveredWs);
                                    win.dragging = null;
                                }
                            }
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "klik: fokus  ·  seret: pindah workspace  ·  klik tengah: tutup  ·  esc"
                        color: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: 10
                        font.letterSpacing: 1
                    }
                }

                // "Hantu" window yang diseret
                Rectangle {
                    visible: win.dragging !== null
                    x: win.dragPos.x - width / 2
                    y: win.dragPos.y - height / 2
                    width: 140
                    height: 34
                    radius: Theme.radiusSmall
                    color: Theme.accent
                    opacity: 0.92

                    Text {
                        anchors.centerIn: parent
                        width: parent.width - 16
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: win.dragging ? (win.dragging.cls || win.dragging.title) : ""
                        color: Theme.accentFg
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 1
                    }
                }
            }

            // Workspace di bawah kursor saat menyeret
            readonly property int hoveredWs: {
                if (dragging === null) return -1;
                for (let i = 0; i < tiles.count; i++) {
                    const t = tiles.itemAt(i);
                    if (!t) continue;
                    const p = t.mapFromItem(body, dragPos.x, dragPos.y);
                    if (p.x >= 0 && p.y >= 0 && p.x <= t.width && p.y <= t.height) return t.ws;
                }
                return -1;
            }
        }
    }
}
