// App launcher, two-panel layout: prompt + current wallpaper + mode tabs on the left,
// results on the right. Open: SUPER+R, the launcher button in the bar,
// or  qs -c shell ipc call launcher toggle
//
//   ↑ ↓ / Ctrl+J Ctrl+K   move        Tab / Shift+Tab   switch mode (Apps · Run · Files · Window)
//   Enter                 run         Esc / click outside   close
//   in Apps:  = calc   :clip clipboard   :wall wallpapers   > shell   ? web search
// Search logic lives in services/Launcher.qml. Every color comes from pywal (Theme).

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.config
import qs.services

PanelWindow {
    id: root

    property string query: ""
    property int current: 0
    property int armed: -1                 // dangerous action waiting for a second Enter
    readonly property var results: Launcher.open ? Launcher.search(query) : []
    readonly property int rowH: 52

    readonly property var modeLabels: ({ apps: "Apps", run: "Run", files: "Files", window: "Window" })

    // pywal colors, animated so a wallpaper change fades in
    property color cBg: Theme.bg
    property color cAccent: Theme.rose
    property color cText: Theme.text
    property color cDim: Theme.muted
    Behavior on cBg { ColorAnimation { duration: 400 } }
    Behavior on cAccent { ColorAnimation { duration: 400 } }
    Behavior on cText { ColorAnimation { duration: 400 } }
    Behavior on cDim { ColorAnimation { duration: 400 } }

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    visible: Launcher.open || panel.opacity > 0

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-launcher"
    WlrLayershell.keyboardFocus: Launcher.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    function refreshMode() {
        current = 0;
        armed = -1;
        if (Launcher.mode === "files") Launcher.findFiles(query);
    }

    onQueryChanged: refreshMode()

    Connections {
        target: Launcher
        function onModeChanged() { root.refreshMode(); }
        function onOpenChanged() {
            if (!Launcher.open) return;
            field.text = "";
            root.query = "";
            root.current = 0;
            root.armed = -1;
            Wallpaper.refresh();
            field.forceActiveFocus();
        }
    }

    onResultsChanged: if (query.startsWith(":clip") && Clipboard.items.length === 0) Clipboard.refresh()

    function move(d) {
        if (results.length === 0) return;
        current = (current + d + results.length) % results.length;
        armed = -1;
        list.positionViewAtIndex(current, ListView.Contain);
    }

    function activate(i) {
        const r = results[i];
        if (!r) return;
        if (r.danger && armed !== i) { armed = i; return; }
        Launcher.run(r);
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Launcher.open = false
    }

    Rectangle {
        id: panel
        width: Math.min(880, root.width - 80)
        height: Math.min(440, root.height - 80)
        anchors.centerIn: parent
        radius: 16
        color: root.cBg
        border.width: 1
        border.color: Qt.rgba(root.cAccent.r, root.cAccent.g, root.cAccent.b, 0.22)

        opacity: Launcher.open ? 1 : 0
        scale: Launcher.open ? 1 : 0.97
        Behavior on opacity { NumberAnimation { duration: 150 } }
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 28

            // ── Left: prompt, wallpaper, mode tabs ───────────────────
            ColumnLayout {
                Layout.preferredWidth: parent.width * 0.44
                Layout.maximumWidth: parent.width * 0.44
                Layout.fillHeight: true
                spacing: 18

                // Prompt + input
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    Layout.leftMargin: 12
                    spacing: 10

                    Text {
                        text: root.modeLabels[Launcher.mode]
                        color: root.cAccent
                        font.family: Theme.font
                        font.pixelSize: 15
                    }

                    Item {
                        Layout.fillWidth: true
                        implicitHeight: 24

                        TextInput {
                            id: field
                            anchors.fill: parent
                            verticalAlignment: TextInput.AlignVCenter
                            color: root.cText
                            selectionColor: Qt.rgba(root.cAccent.r, root.cAccent.g, root.cAccent.b, 0.35)
                            selectedTextColor: root.cText
                            cursorDelegate: Rectangle { width: 2; color: root.cAccent }
                            font.family: Theme.font
                            font.pixelSize: 15
                            clip: true
                            focus: Launcher.open
                            onTextChanged: root.query = text

                            Keys.onPressed: event => {
                                const ctrl = event.modifiers & Qt.ControlModifier;
                                if (event.key === Qt.Key_Escape) {
                                    if (text !== "") text = ""; else Launcher.open = false;
                                } else if (event.key === Qt.Key_Tab) {
                                    Launcher.cycleMode(1);
                                } else if (event.key === Qt.Key_Backtab) {
                                    Launcher.cycleMode(-1);
                                } else if (event.key === Qt.Key_Down || (ctrl && event.key === Qt.Key_J)) {
                                    root.move(1);
                                } else if (event.key === Qt.Key_Up || (ctrl && event.key === Qt.Key_K)) {
                                    root.move(-1);
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    root.activate(root.current);
                                } else {
                                    return;
                                }
                                event.accepted = true;
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: field.text === ""
                            text: Launcher.mode === "run" ? "Command" : Launcher.mode === "files" ? "File name" : "Search"
                            color: root.cDim
                            font.family: Theme.font
                            font.pixelSize: 15
                        }
                    }
                }

                // Current wallpaper
                ClippingRectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 12
                    color: Theme.surface

                    Image {
                        anchors.fill: parent
                        source: Wallpaper.current !== "" ? "file://" + Wallpaper.current : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: 800
                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 300 } }
                    }
                }

                // Mode tabs
                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 4
                    spacing: 6

                    Repeater {
                        model: Launcher.modes
                        Rectangle {
                            id: tab
                            required property string modelData
                            readonly property bool active: Launcher.mode === modelData

                            Layout.fillWidth: true
                            implicitHeight: 30
                            radius: 8
                            color: active ? Qt.rgba(root.cAccent.r, root.cAccent.g, root.cAccent.b, 0.16)
                                 : tabMouse.containsMouse ? Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.06)
                                 : "transparent"
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text: root.modeLabels[tab.modelData]
                                color: tab.active ? root.cAccent : root.cText
                                font.family: Theme.font
                                font.pixelSize: 14
                            }

                            MouseArea {
                                id: tabMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { Launcher.mode = tab.modelData; field.forceActiveFocus(); }
                            }
                        }
                    }
                }
            }

            // ── Right: results ───────────────────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Text {
                    anchors.centerIn: parent
                    visible: root.results.length === 0
                    text: Launcher.mode === "files" ? (root.query.length < 2 ? "Type at least 2 letters" : "No files found")
                        : Launcher.mode === "run" ? "Type a command"
                        : Launcher.mode === "window" ? "No open windows"
                        : "No matches"
                    color: root.cDim
                    font.family: Theme.font
                    font.pixelSize: 13
                }

                ListView {
                    id: list
                    anchors.fill: parent
                    clip: true
                    model: root.results
                    currentIndex: root.current
                    spacing: 0
                    boundsBehavior: Flickable.StopAtBounds
                    highlightMoveDuration: 110
                    highlightResizeDuration: 0

                    // Solid accent block behind the selected row
                    highlight: Rectangle {
                        radius: 8
                        color: root.armed === root.current ? Theme.danger : root.cAccent
                    }

                    delegate: Item {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property bool isCurrent: index === root.current
                        readonly property color fg: isCurrent ? root.cBg : root.cText

                        width: ListView.view.width
                        height: root.rowH

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 16

                            // App icon / thumbnail, else a glyph
                            Item {
                                implicitWidth: 24
                                implicitHeight: 24

                                ClippingRectangle {
                                    anchors.fill: parent
                                    visible: img.status === Image.Ready
                                    radius: row.modelData.kind === "wall" || row.modelData.kind === "clip" ? 5 : 0
                                    color: "transparent"
                                    Image {
                                        id: img
                                        anchors.fill: parent
                                        source: row.modelData.icon ?? ""
                                        fillMode: row.modelData.kind === "wall" || row.modelData.kind === "clip"
                                                  ? Image.PreserveAspectCrop : Image.PreserveAspectFit
                                        sourceSize.width: 48
                                        sourceSize.height: 48
                                        asynchronous: true
                                    }
                                }
                                Text {
                                    anchors.centerIn: parent
                                    visible: img.status !== Image.Ready
                                    text: row.modelData.glyph ?? ""
                                    color: row.isCurrent ? row.fg : row.modelData.danger ? Theme.danger : root.cDim
                                    font.family: Theme.font
                                    font.pixelSize: 17
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.armed === row.index ? "Press Enter again to " + row.modelData.title.toLowerCase()
                                                               : row.modelData.title
                                color: row.fg
                                font.family: Theme.font
                                font.pixelSize: row.modelData.kind === "calc" ? 18 : 15
                                elide: Text.ElideRight
                            }

                            // Secondary info (folder, app id, "recent") only where it helps
                            Text {
                                visible: text !== "" && (row.modelData.kind === "file" || row.modelData.kind === "window"
                                                         || row.modelData.kind === "run" || row.modelData.kind === "calc")
                                Layout.maximumWidth: list.width * 0.4
                                text: row.modelData.sub ?? ""
                                color: row.isCurrent ? Qt.rgba(row.fg.r, row.fg.g, row.fg.b, 0.7) : root.cDim
                                font.family: Theme.font
                                font.pixelSize: 11
                                elide: Text.ElideMiddle
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: { root.current = row.index; root.armed = -1; }
                            onClicked: root.activate(row.index)
                        }
                    }
                }
            }
        }
    }
}
