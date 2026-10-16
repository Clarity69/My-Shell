// Dynamic island: pil di tengah bar yang berubah bentuk sesuai keadaan.
//   idle      jam (+ cuaca, titik kalau ada notifikasi)
//   media     cover kecil + judul lagu + equalizer      (MPRIS: Spotify, browser, mpv, ...)
//   osd       volume / kecerahan saat berubah
//   notif     notifikasi baru (klik = buka, klik kanan = tutup)
//   expanded  hover / klik: kontrol media lengkap, atau jam besar + tanggal + cuaca
//
// Muncul kalau layout bar aktif punya `island: true` (lihat bar/BarState.qml).
// Bagian tengah bar disembunyikan, island yang mengisi tempatnya.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import qs.config
import qs.services
import qs.bar

Scope {
    id: root

    readonly property var lay: BarState.layout
    readonly property bool active: Config.islandEnabled && BarState.shown && lay.island === true

    // ── Media ────────────────────────────────────────────────────────
    readonly property var players: Mpris.players.values
    readonly property var player: players.find(p => p.isPlaying) ?? players[0] ?? null
    readonly property bool hasMedia: player !== null && (player.trackTitle ?? "") !== ""
    readonly property bool playing: hasMedia && player.isPlaying

    // ── Keadaan sementara ────────────────────────────────────────────
    property string osdKind: ""          // "volume" | "brightness"
    property real osdValue: 0
    property bool osdMuted: false
    property var notif: null
    property bool expanded: false
    property bool pinned: false          // dibuka lewat klik, tidak tertutup saat mouse keluar
    property bool ready: false           // abaikan perubahan volume/kecerahan saat start

    readonly property string mode: notif ? "notif"
                                 : osdKind !== "" ? "osd"
                                 : expanded ? "expanded"
                                 : hasMedia ? "media" : "idle"

    function showOsd(kind, value, muted) {
        if (!Config.islandOsd || !ready || !active) return;
        osdKind = kind;
        osdValue = Math.max(0, Math.min(1, value));
        osdMuted = muted;
        osdTimer.restart();
    }

    function fmt(s) {
        s = Math.max(0, Math.floor(s || 0));
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    function hoverIn()  { collapseTimer.stop(); if (!expanded) expandTimer.restart(); }
    function hoverOut() { expandTimer.stop(); if (!pinned) collapseTimer.restart(); }

    function togglePinned() {
        pinned = !(pinned && expanded);
        expanded = pinned;
    }

    Timer { interval: 1500; running: true; onTriggered: root.ready = true }
    Timer { id: osdTimer; interval: 1400; onTriggered: root.osdKind = "" }
    Timer { id: notifTimer; interval: Math.max(3000, Config.notifTimeout); onTriggered: root.notif = null }
    Timer { id: expandTimer; interval: 250; onTriggered: root.expanded = true }
    Timer { id: collapseTimer; interval: 450; onTriggered: { root.expanded = false; root.pinned = false; } }

    // Posisi lagu tidak diperbarui otomatis oleh MPRIS
    Timer {
        interval: 1000
        repeat: true
        running: root.playing && root.mode === "expanded"
        onTriggered: root.player.positionChanged()
    }

    // ── Volume (PipeWire, langsung bereaksi ke tombol volume) ────────
    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [root.sink] }

    Connections {
        target: root.sink?.audio ?? null
        ignoreUnknownSignals: true
        function onVolumeChanged() { root.showOsd("volume", root.sink.audio.volume, root.sink.audio.muted); }
        function onMutedChanged()  { root.showOsd("volume", root.sink.audio.volume, root.sink.audio.muted); }
    }

    // ── Kecerahan (baca /sys/class/backlight berkala, ringan) ────────
    property string backlight: ""
    property int maxBright: 0

    Process {
        running: true
        command: ["sh", "-c", 'd=$(ls /sys/class/backlight 2>/dev/null | head -n1); [ -n "$d" ] && echo "$d $(cat /sys/class/backlight/$d/max_brightness)"']
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split(" ");
                if (p.length === 2 && parseInt(p[1]) > 0) {
                    root.backlight = p[0];
                    root.maxBright = parseInt(p[1]);
                }
            }
        }
    }

    FileView {
        id: brightFile
        property int last: -1
        path: root.backlight !== "" ? "/sys/class/backlight/" + root.backlight + "/brightness" : ""
        printErrors: false
        onLoaded: {
            const v = parseInt(text());
            if (isNaN(v)) return;
            if (last >= 0 && v !== last) root.showOsd("brightness", v / root.maxBright, false);
            last = v;
        }
    }

    Timer {
        interval: 250
        repeat: true
        running: root.active && Config.islandOsd && root.backlight !== ""
        onTriggered: brightFile.reload()
    }

    // ── Notifikasi ───────────────────────────────────────────────────
    // Selama island aktif, popup biasa diganti island (kecuali yang critical)
    Binding {
        target: Notifications
        property: "islandHandles"
        value: root.active && Config.islandNotifications
    }

    Connections {
        target: Notifications
        function onArrived(n) {
            if (!Notifications.islandHandles) return;
            root.notif = n;
            notifTimer.restart();
            n.closed.connect(() => { if (root.notif === n) root.notif = null; });
        }
    }

    // ── Window, satu per monitor ─────────────────────────────────────
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData

            screen: modelData
            visible: root.active
            anchors.top: true                       // hanya atas = otomatis di tengah
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-island"
            implicitWidth: 520
            implicitHeight: 220
            color: "transparent"

            // Klik di luar pil tembus ke aplikasi di bawahnya
            mask: Region { item: pill }

            readonly property int compactH: root.lay.style === "islands" ? root.lay.height : root.lay.height - 6
            readonly property int topY: (root.lay.margin?.top ?? 0) + Math.round((root.lay.height - compactH) / 2)

            readonly property int targetW: ({
                idle: 150, media: 290, osd: 260, notif: 400,
                expanded: root.hasMedia ? 420 : 300
            })[root.mode]
            readonly property int targetH: ({
                idle: compactH, media: compactH, osd: compactH, notif: 64,
                expanded: root.hasMedia ? 132 : 104
            })[root.mode]

            Rectangle {
                id: pill
                x: Math.round((win.width - width) / 2)
                y: win.topY
                width: win.targetW
                height: win.targetH
                radius: Math.min(height / 2, 26)
                color: Theme.bg
                border.width: 1
                border.color: Theme.border
                clip: true

                Behavior on width  { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
                Behavior on height { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
                Behavior on radius { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

                HoverHandler {
                    onHoveredChanged: hovered ? root.hoverIn() : root.hoverOut()
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        if (root.mode === "notif") {
                            if (mouse.button === Qt.RightButton) Notifications.dismiss(root.notif);
                            else Notifications.activate(root.notif);
                            root.notif = null;
                        } else if (mouse.button === Qt.LeftButton) {
                            root.togglePinned();
                        }
                    }
                }

                // ── idle ─────────────────────────────────────────────
                Face {
                    shown: root.mode === "idle"
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 10

                        Text {
                            text: Qt.formatDateTime(BarState.clock.date, "hh:mm")
                            color: Theme.text
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                            font.bold: true
                        }
                        Text {
                            visible: Weather.available && Config.weatherEnabled
                            text: Weather.icon + " " + Math.round(Weather.temp) + "°"
                            color: Theme.subtext
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 2
                        }
                        Rectangle {
                            visible: Notifications.count > 0 && !Notifications.dnd
                            implicitWidth: 6; implicitHeight: 6; radius: 3
                            color: Theme.rose
                        }
                    }
                }

                // ── media (ringkas) ──────────────────────────────────
                Face {
                    shown: root.mode === "media"
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 14
                        spacing: 10

                        Cover {
                            size: win.compactH - 8
                            radius: (win.compactH - 8) / 2
                            source: root.player?.trackArtUrl ?? ""
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root.player?.trackTitle ?? ""
                            color: Theme.text
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 1
                            elide: Text.ElideRight
                        }
                        Bars { playing: root.playing }
                    }
                }

                // ── osd ──────────────────────────────────────────────
                Face {
                    shown: root.mode === "osd"
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 10

                        Text {
                            text: root.osdKind === "brightness" ? Icons.brightness
                                : root.osdMuted ? Icons.volumeOff : Icons.volume
                            color: Theme.text
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize + 2
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 6
                            radius: 3
                            color: Theme.border
                            Rectangle {
                                width: parent.width * root.osdValue
                                height: parent.height
                                radius: 3
                                color: root.osdMuted ? Theme.muted : Theme.accent
                                Behavior on width { NumberAnimation { duration: 120 } }
                            }
                        }
                        Text {
                            Layout.preferredWidth: 32
                            horizontalAlignment: Text.AlignRight
                            text: Math.round(root.osdValue * 100)
                            color: Theme.subtext
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 2
                        }
                    }
                }

                // ── notifikasi ───────────────────────────────────────
                Face {
                    shown: root.mode === "notif"
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 18
                        spacing: 12

                        IconImage {
                            implicitSize: 34
                            source: {
                                const n = root.notif;
                                if (!n) return "";
                                return Notifications.iconSource(n.image) || Notifications.iconSource(n.appIcon);
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                Layout.fillWidth: true
                                text: root.notif ? (root.notif.summary || root.notif.appName) : ""
                                color: Theme.text
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 1
                                font.bold: true
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                text: root.notif ? root.notif.body.replace(/<[^>]*>/g, "").replace(/\n/g, " ") : ""
                                visible: text !== ""
                                color: Theme.subtext
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 2
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                // ── expanded: media ──────────────────────────────────
                Face {
                    shown: root.mode === "expanded" && root.hasMedia
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 14

                        Cover { size: 96; radius: 14; source: root.player?.trackArtUrl ?? "" }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                Layout.fillWidth: true
                                text: root.player?.trackTitle ?? ""
                                color: Theme.text
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize
                                font.bold: true
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                text: root.player?.trackArtist || root.player?.identity || ""
                                color: Theme.subtext
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 2
                                elide: Text.ElideRight
                            }

                            Item { Layout.fillHeight: true }

                            // Progres (klik untuk lompat kalau player mendukung)
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 4
                                radius: 2
                                color: Theme.border
                                visible: (root.player?.length ?? 0) > 0
                                Rectangle {
                                    width: parent.width * Math.min(1, (root.player?.position ?? 0) / Math.max(1, root.player?.length ?? 1))
                                    height: parent.height
                                    radius: 2
                                    color: Theme.accent
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -6
                                    enabled: root.player?.canSeek ?? false
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: mouse => root.player.position = root.player.length * Math.max(0, Math.min(1, mouse.x / width))
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: root.fmt(root.player?.position) + " / " + root.fmt(root.player?.length)
                                    visible: (root.player?.length ?? 0) > 0
                                    color: Theme.muted
                                    font.family: Theme.font
                                    font.pixelSize: 10
                                }
                                Item { Layout.fillWidth: true }
                                Control { icon: String.fromCodePoint(0xF04AE); enabled: root.player?.canGoPrevious ?? false; onActivated: root.player.previous() }
                                Control {
                                    icon: root.playing ? String.fromCodePoint(0xF03E4) : String.fromCodePoint(0xF040A)
                                    big: true
                                    enabled: root.player?.canTogglePlaying ?? false
                                    onActivated: root.player.togglePlaying()
                                }
                                Control { icon: String.fromCodePoint(0xF04AD); enabled: root.player?.canGoNext ?? false; onActivated: root.player.next() }
                            }
                        }
                    }
                }

                // ── expanded: tanpa media ────────────────────────────
                Face {
                    shown: root.mode === "expanded" && !root.hasMedia
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: Qt.formatDateTime(BarState.clock.date, "hh:mm")
                            color: Theme.text
                            font.family: Theme.serif
                            font.pixelSize: 34
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: Qt.formatDateTime(BarState.clock.date, "dddd, d MMMM")
                            color: Theme.subtext
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 2
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            visible: Weather.available && Config.weatherEnabled
                            text: Weather.icon + "  " + Math.round(Weather.temp) + "°  " + Weather.description
                            color: Theme.muted
                            font.family: Theme.font
                            font.pixelSize: 10
                        }
                    }
                }
            }
        }
    }

    // ── Komponen kecil ───────────────────────────────────────────────

    // Satu "wajah" island; cross-fade saat mode berganti
    component Face: Item {
        property bool shown: false
        anchors.fill: parent
        opacity: shown ? 1 : 0
        visible: opacity > 0
        scale: shown ? 1 : 0.92
        Behavior on opacity { NumberAnimation { duration: shown ? 260 : 120 } }
        Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
    }

    // Cover album, ikon musik kalau tidak ada gambar
    component Cover: ClippingRectangle {
        id: cover
        property int size: 24
        property string source: ""
        implicitWidth: size
        implicitHeight: size
        Layout.preferredWidth: size
        Layout.preferredHeight: size
        color: Theme.border

        Text {
            anchors.centerIn: parent
            visible: art.status !== Image.Ready
            text: String.fromCodePoint(0xF075A)
            color: Theme.subtext
            font.family: Theme.font
            font.pixelSize: cover.size * 0.5
        }
        Image {
            id: art
            anchors.fill: parent
            source: cover.source
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: 192
            sourceSize.height: 192
        }
    }

    // Equalizer palsu yang bergerak selama musik diputar
    component Bars: Row {
        id: bars
        property bool playing: false
        spacing: 2
        Layout.alignment: Qt.AlignVCenter
        Repeater {
            model: 4
            Rectangle {
                required property int index
                width: 3
                height: 4
                radius: 1.5
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.accent
                SequentialAnimation on height {
                    running: bars.playing
                    loops: Animation.Infinite
                    NumberAnimation { to: 12 - index * 2; duration: 260 + index * 70; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 4; duration: 300 + index * 60; easing.type: Easing.InOutSine }
                }
            }
        }
    }

    // Tombol media
    component Control: Text {
        property string icon: ""
        property bool big: false
        signal activated()
        text: icon
        color: enabled ? Theme.text : Theme.muted
        font.family: Theme.font
        font.pixelSize: big ? 24 : 18
        MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.activated()
        }
    }
}
