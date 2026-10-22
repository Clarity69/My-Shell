// App launcher on the focused monitor. Open: SUPER+R, the launcher button in the bar,
// or  qs -c shell ipc call launcher toggle
//
//   ↑ ↓ / Tab / Ctrl+J Ctrl+K   move      Enter   run      Esc / click outside   close
//   prefixes:  =  calc   :clip  clipboard   :wall  wallpapers   >  shell   ?  web search
// Search logic lives in services/Launcher.qml. Every color comes from pywal (Theme),
// so the launcher re-tints itself whenever the wallpaper changes.

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
    readonly property var results: Launcher.open ? Launcher.search(query).slice(0, query === "" ? 6 : 40) : []
    readonly property int rowH: 40
    readonly property int visibleRows: 7

    // pywal-derived colors, animated so a wallpaper change fades in smoothly
    property color cBg: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.94)
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

    onQueryChanged: { current = 0; armed = -1; }

    Connections {
        target: Launcher
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

    // Click anywhere outside the panel to close (no dimming: stay out of the way)
    MouseArea {
        anchors.fill: parent
        onClicked: Launcher.open = false
    }

    Rectangle {
        id: panel
        width: Math.min(520, root.width - 64)
        height: search.height + (root.results.length > 0 ? listBox.height + 6 : 0)
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(root.height * 0.32)
        radius: 14
        color: root.cBg
        border.width: 1
        border.color: Qt.rgba(root.cAccent.r, root.cAccent.g, root.cAccent.b, 0.28)
        clip: true

        Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        opacity: Launcher.open ? 1 : 0
        transform: Translate {
            y: Launcher.open ? 0 : -8
            Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }
        Behavior on opacity { NumberAnimation { duration: 140 } }

        MouseArea { anchors.fill: parent }     // keep clicks inside from closing

        // ── Search ───────────────────────────────────────────────────
        Item {
            id: search
            width: parent.width
            height: 50

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 18
                spacing: 12

                Text {
                    text: Icons.search
                    color: field.text !== "" ? root.cAccent : root.cDim
                    font.family: Theme.font
                    font.pixelSize: 16
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    TextInput {
                        id: field
                        anchors.fill: parent
                        verticalAlignment: TextInput.AlignVCenter
                        color: root.cText
                        selectionColor: Qt.rgba(root.cAccent.r, root.cAccent.g, root.cAccent.b, 0.35)
                        selectedTextColor: root.cText
                        cursorDelegate: Rectangle { width: 2; color: root.cAccent }
                        font.family: Theme.font
                        font.pixelSize: 16
                        clip: true
                        focus: Launcher.open
                        onTextChanged: root.query = text

                        Keys.onPressed: event => {
                            const ctrl = event.modifiers & Qt.ControlModifier;
                            if (event.key === Qt.Key_Escape) {
                                if (text !== "") text = ""; else Launcher.open = false;
                            } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab || (ctrl && event.key === Qt.Key_J)) {
                                root.move(1);
                            } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab || (ctrl && event.key === Qt.Key_K)) {
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
                        text: "search"
                        color: root.cDim
                        font.family: Theme.font
                        font.pixelSize: 16
                    }
                }

                // Mode tag for prefixes
                Text {
                    readonly property string mode: root.query.startsWith(":clip") ? "clipboard"
                        : root.query.startsWith(":wall") ? "wallpaper"
                        : root.query.startsWith(">") ? "shell"
                        : root.query.startsWith("?") ? "web"
                        : root.query.startsWith("=") ? "calc" : ""
                    visible: mode !== ""
                    text: mode
                    color: root.cAccent
                    font.family: Theme.font
                    font.pixelSize: 10
                    font.letterSpacing: 1.5
                    font.capitalization: Font.AllUppercase
                }
            }

            // Thin accent line that grows while typing
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                height: 1
                width: root.results.length > 0 ? parent.width - 36 : 0
                color: Qt.rgba(root.cAccent.r, root.cAccent.g, root.cAccent.b, 0.25)
                Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }
        }

        // ── Results ──────────────────────────────────────────────────
        Item {
            id: listBox
            anchors.top: search.bottom
            anchors.topMargin: 6
            width: parent.width
            height: Math.min(root.visibleRows, root.results.length) * root.rowH

            ListView {
                id: list
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                clip: true
                model: root.results
                currentIndex: root.current
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: 100
                highlightResizeDuration: 0

                highlight: Rectangle {
                    radius: 9
                    color: root.armed === root.current
                           ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.18)
                           : Qt.rgba(root.cAccent.r, root.cAccent.g, root.cAccent.b, 0.14)
                }

                delegate: Item {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool isCurrent: index === root.current
                    readonly property bool isArmed: root.armed === index

                    width: ListView.view.width
                    height: root.rowH

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        // App icon / thumbnail, else a glyph
                        Item {
                            implicitWidth: 22
                            implicitHeight: 22

                            ClippingRectangle {
                                anchors.fill: parent
                                visible: img.status === Image.Ready
                                radius: row.modelData.kind === "app" ? 0 : 5
                                color: "transparent"
                                Image {
                                    id: img
                                    anchors.fill: parent
                                    source: row.modelData.icon ?? ""
                                    fillMode: row.modelData.kind === "app" ? Image.PreserveAspectFit : Image.PreserveAspectCrop
                                    sourceSize.width: 48
                                    sourceSize.height: 48
                                    asynchronous: true
                                }
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: img.status !== Image.Ready
                                text: row.modelData.glyph ?? ""
                                color: row.modelData.danger ? Theme.danger
                                     : row.isCurrent ? root.cAccent : root.cDim
                                font.family: Theme.font
                                font.pixelSize: 15
                            }
                        }

                        Text {
                            Layout.fillWidth: !subText.visible
                            Layout.maximumWidth: list.width * 0.6
                            text: row.modelData.title
                            color: row.isArmed ? Theme.danger : row.isCurrent ? root.cText : Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.78)
                            font.family: Theme.font
                            font.pixelSize: row.modelData.kind === "calc" ? 17 : 14
                            font.weight: row.isCurrent ? Font.DemiBold : Font.Normal
                            elide: Text.ElideRight
                        }

                        // Description only on the selected row: keeps the list quiet
                        Text {
                            id: subText
                            Layout.fillWidth: true
                            visible: row.isCurrent && text !== ""
                            text: row.isArmed ? "enter again to confirm" : (row.modelData.sub ?? "")
                            color: row.isArmed ? Theme.danger : root.cDim
                            font.family: Theme.font
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: row.isCurrent
                            text: "↵"
                            color: root.cAccent
                            font.family: Theme.font
                            font.pixelSize: 13
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
