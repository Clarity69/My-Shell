// Profile: a bento-style dashboard.
//   hero        current wallpaper (slow Ken Burns zoom), hostname, live clock, pywal palette strip
//   bento grid  big CPU card with graph + three glowing ring gauges + weather
//   now playing blurred cover art as the backdrop
//   quick settings, spec sheet
// Cards slide in one after another every time the page opens and lift on hover.

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.config
import qs.components
import qs.services

Page {
    id: root

    // Replays the entrance animation each time the page is opened
    property bool revealed: true
    onOpened: {
        Wallpaper.refresh();
        revealed = false;
        Qt.callLater(() => root.revealed = true);
    }
    onPoll: {
        SystemInfo.refresh();
        SystemStats.refresh();
        Battery.refresh();
        Network.refresh();
        Bluetooth.refresh();
        NightLight.refresh();
        Notifications.refresh();
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    readonly property var down: SystemStats.formatRate(SystemStats.rxRate)
    readonly property var up: SystemStats.formatRate(SystemStats.txRate)
    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
    readonly property bool hasMedia: player !== null && (player.trackTitle ?? "") !== ""
    readonly property string greeting: {
        const h = clock.date.getHours();
        return h < 5 ? "good night" : h < 12 ? "good morning" : h < 18 ? "good afternoon" : "good evening";
    }

    // MPRIS does not push position updates by itself
    Timer {
        interval: 1000
        repeat: true
        running: root.active && root.hasMedia && root.player.isPlaying
        onTriggered: root.player.positionChanged()
    }

    // ── Hero ─────────────────────────────────────────────────────────
    Card {
        Layout.fillWidth: true
        implicitHeight: 210
        shown: root.revealed
        order: 0
        hoverable: false
        color: "transparent"
        border.width: 0

        ClippingRectangle {
            anchors.fill: parent
            radius: Theme.radius + 6
            color: Theme.surface

            // Wallpaper with a slow, endless zoom
            Image {
                id: wall
                anchors.fill: parent
                source: Wallpaper.current !== "" ? "file://" + Wallpaper.current : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: 1000
                opacity: status === Image.Ready ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 600 } }

                SequentialAnimation on scale {
                    running: root.active
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 1.12; duration: 22000; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 1.12; to: 1.0; duration: 22000; easing.type: Easing.InOutSine }
                }
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0;  color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.15) }
                    GradientStop { position: 0.5;  color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.45) }
                    GradientStop { position: 1.0;  color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.95) }
                }
            }

            // Kicker with a pulsing "live" dot
            Row {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: 18
                spacing: 8

                Item {
                    width: 8; height: 8
                    anchors.verticalCenter: parent.verticalCenter
                    Rectangle {
                        anchors.centerIn: parent
                        width: 8; height: 8; radius: 4
                        color: Theme.rose
                    }
                    Rectangle {
                        id: pulse
                        anchors.centerIn: parent
                        width: 8
                        height: width
                        radius: width / 2
                        color: "transparent"
                        border.width: 1.5
                        border.color: Theme.rose
                        NumberAnimation on width {
                            running: root.active
                            loops: Animation.Infinite
                            from: 8; to: 22; duration: 1600; easing.type: Easing.OutCubic
                        }
                        NumberAnimation on opacity {
                            running: root.active
                            loops: Animation.Infinite
                            from: 0.9; to: 0; duration: 1600; easing.type: Easing.OutCubic
                        }
                    }
                }
                Text {
                    text: "SYSTEM · DOSSIER · LIVE"
                    color: Theme.text
                    opacity: 0.85
                    font.family: Theme.font
                    font.pixelSize: 10
                    font.letterSpacing: 2
                }
            }

            // Clock with a blinking colon
            ColumnLayout {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 16
                spacing: 0

                Row {
                    Layout.alignment: Qt.AlignRight
                    Text {
                        text: Qt.formatDateTime(clock.date, "hh")
                        color: Theme.text
                        font.family: Theme.serif
                        font.pixelSize: 36
                    }
                    Text {
                        text: ":"
                        color: Theme.rose
                        font.family: Theme.serif
                        font.pixelSize: 36
                        opacity: clock.date.getSeconds() % 2 === 0 ? 1 : 0.15
                        Behavior on opacity { NumberAnimation { duration: 300 } }
                    }
                    Text {
                        text: Qt.formatDateTime(clock.date, "mm")
                        color: Theme.text
                        font.family: Theme.serif
                        font.pixelSize: 36
                    }
                }
                Text {
                    Layout.alignment: Qt.AlignRight
                    text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                    color: Theme.text
                    opacity: 0.75
                    font.family: Theme.font
                    font.pixelSize: 11
                }
            }

            // Identity
            ColumnLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 18
                anchors.bottomMargin: 20
                spacing: 0

                Text {
                    text: root.greeting + ", " + SystemInfo.user
                    color: Theme.text
                    opacity: 0.85
                    font.family: Theme.serif
                    font.italic: true
                    font.pixelSize: Theme.fontSize + 3
                }
                Text {
                    Layout.fillWidth: true
                    text: SystemInfo.host
                    color: Theme.text
                    font.family: Theme.serif
                    font.pixelSize: 58
                    font.letterSpacing: -1
                    elide: Text.ElideRight
                }
                RowLayout {
                    spacing: 6
                    Chip { text: SystemInfo.os !== "" ? SystemInfo.os : "linux" }
                    Chip { visible: SystemInfo.compositor !== ""; text: "hyprland " + SystemInfo.compositor }
                    Chip { visible: SystemInfo.uptime !== ""; text: "up " + SystemInfo.uptime }
                }
            }

            // pywal palette as a thin strip along the bottom edge
            Row {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 4
                visible: Theme.palette.length > 0
                Repeater {
                    model: Theme.palette.slice(0, 16)
                    Rectangle {
                        required property var modelData
                        width: parent.width / Math.min(16, Theme.palette.length)
                        height: 4
                        color: modelData
                    }
                }
            }
        }
    }

    // ── Bento grid ───────────────────────────────────────────────────
    GridLayout {
        Layout.fillWidth: true
        Layout.topMargin: 2
        columns: 4
        columnSpacing: Theme.gap
        rowSpacing: Theme.gap

        // Big CPU card: count-up number + smooth graph (2×2)
        Card {
            Layout.columnSpan: 2
            Layout.rowSpan: 2
            Layout.fillWidth: true
            Layout.preferredWidth: 2
            implicitHeight: 2 * 128 + Theme.gap
            shown: root.revealed
            order: 1

            ColumnLayout {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: 16
                spacing: 0

                Kicker { text: "processor" }
                Row {
                    spacing: 4
                    CountUp {
                        id: cpuNum
                        target: SystemStats.cpu * 100
                        font.pixelSize: 64
                    }
                    Text {
                        anchors.baseline: cpuNum.baseline
                        text: "%"
                        color: Theme.subtext
                        font.family: Theme.serif
                        font.pixelSize: 24
                    }
                }
                Text {
                    text: SystemStats.temp > 0 ? "core " + SystemStats.temp + "°C" : "load"
                    color: Theme.subtext
                    font.family: Theme.font
                    font.pixelSize: 11
                }
            }

            Text {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 16
                horizontalAlignment: Text.AlignRight
                text: "↓ " + root.down.v + " " + root.down.u + "\n↑ " + root.up.v + " " + root.up.u
                color: Theme.subtext
                font.family: Theme.font
                font.pixelSize: 10
                lineHeight: 1.3
            }

            Graph {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 1
                height: parent.height * 0.48
                points: SystemStats.history
            }
        }

        Gauge {
            order: 2
            shown: root.revealed
            label: "memory"
            value: SystemStats.mem
            text: Math.round(SystemStats.mem * 100) + "%"
            sub: SystemStats.formatKiB(SystemStats.memUsed) + " / " + SystemStats.formatKiB(SystemStats.memTotal)
        }

        Gauge {
            order: 3
            shown: root.revealed
            label: "thermal"
            value: SystemStats.temp > 0 ? Math.min(1, SystemStats.temp / 100) : 0
            text: SystemStats.temp > 0 ? SystemStats.temp + "°" : "—"
            sub: SystemStats.temp >= 80 ? "running hot" : "cpu core"
            hot: SystemStats.temp >= 80
        }

        // Weather
        Card {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            implicitHeight: 128
            shown: root.revealed
            order: 4

            Kicker {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: 12
                text: Weather.city !== "" ? Weather.city : "weather"
            }
            Text {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 10
                text: Weather.available ? Weather.icon : ""
                color: Theme.rose
                font.family: Theme.font
                font.pixelSize: 30
            }
            ColumnLayout {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.margins: 12
                spacing: 0
                Text {
                    text: Weather.available ? Math.round(Weather.temp) + "°" : "—"
                    color: Theme.text
                    font.family: Theme.serif
                    font.pixelSize: 38
                }
                Text {
                    text: Weather.available ? Weather.description : "no data"
                    color: Theme.subtext
                    font.family: Theme.font
                    font.pixelSize: 10
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Weather.refresh()
            }
        }

        Gauge {
            order: 5
            shown: root.revealed
            label: Battery.available ? "battery" : "uptime"
            value: Battery.available ? Battery.percent / 100 : -1
            text: Battery.available ? Battery.percent + "%" : SystemInfo.uptime
            sub: Battery.available ? (Battery.charging ? "charging" : Battery.status.toLowerCase()) : "since boot"
            hot: Battery.available && Battery.percent <= 15 && !Battery.charging
        }
    }

    // ── Now playing: blurred cover art as the backdrop ───────────────
    Card {
        Layout.fillWidth: true
        visible: root.hasMedia
        implicitHeight: 96
        shown: root.revealed
        order: 6
        color: "transparent"

        ClippingRectangle {
            anchors.fill: parent
            radius: Theme.radius
            color: Theme.surface

            Image {
                id: backdrop
                anchors.fill: parent
                anchors.margins: -40
                source: root.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: 256
                layer.enabled: true
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blur: 1.0
                    blurMax: 64
                    saturation: 0.2
                }
            }
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.55)
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 14

                ClippingRectangle {
                    implicitWidth: 68
                    implicitHeight: 68
                    radius: Theme.radius
                    color: Theme.surface2
                    Image {
                        anchors.fill: parent
                        source: root.player?.trackArtUrl ?? ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: 160
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Kicker { text: "now playing" }
                    Text {
                        Layout.fillWidth: true
                        text: root.player?.trackTitle ?? ""
                        color: Theme.text
                        font.family: Theme.serif
                        font.pixelSize: Theme.fontSize + 5
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        text: root.player?.trackArtist || root.player?.identity || ""
                        color: Theme.subtext
                        font.family: Theme.font
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        implicitHeight: 3
                        radius: 1.5
                        visible: (root.player?.length ?? 0) > 0
                        color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.15)
                        Rectangle {
                            width: parent.width * Math.min(1, (root.player?.position ?? 0) / Math.max(1, root.player?.length ?? 1))
                            height: parent.height
                            radius: 1.5
                            color: Theme.rose
                        }
                    }
                }

                IconButton { icon: String.fromCodePoint(0xF04AE); onClicked: root.player.previous() }
                IconButton {
                    icon: root.player?.isPlaying ? String.fromCodePoint(0xF03E4) : String.fromCodePoint(0xF040A)
                    size: 44
                    baseColor: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12)
                    onClicked: root.player.togglePlaying()
                }
                IconButton { icon: String.fromCodePoint(0xF04AD); onClicked: root.player.next() }
            }
        }
    }

    // ── Quick settings ───────────────────────────────────────────────
    Card {
        Layout.fillWidth: true
        Layout.topMargin: 4
        implicitHeight: quick.implicitHeight
        shown: root.revealed
        order: 7
        hoverable: false
        color: "transparent"
        border.width: 0

        GridLayout {
            id: quick
            anchors.left: parent.left
            anchors.right: parent.right
            columns: 2
            columnSpacing: Theme.gap
            rowSpacing: Theme.gap

            QuickToggle {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                icon: Network.ethConnected ? Icons.ethernet : Network.enabled ? Icons.wifi : Icons.wifiOff
                label: "Wi-Fi"
                sublabel: Network.ssid !== "" ? Network.ssid
                        : Network.ethConnected ? "Off · via LAN"
                        : Network.enabled ? "Not connected" : "Off"
                active: Network.enabled
                busy: Network.busy
                onClicked: Network.toggle()
            }
            QuickToggle {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                icon: Bluetooth.powered ? Icons.bluetooth : Icons.bluetoothOff
                label: "Bluetooth"
                sublabel: !Bluetooth.available ? "No adapter"
                        : !Bluetooth.powered ? "Off"
                        : (Bluetooth.device !== "" ? Bluetooth.device : "On")
                active: Bluetooth.powered
                busy: Bluetooth.busy
                enabled: Bluetooth.available
                onClicked: Bluetooth.toggle()
            }
            QuickToggle {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                icon: Icons.night
                label: "Night light"
                sublabel: !NightLight.available ? "hyprsunset missing"
                        : NightLight.active ? NightLight.temperature + "K" : "Off"
                active: NightLight.active
                enabled: NightLight.available
                onClicked: NightLight.toggle()
            }
            QuickToggle {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                icon: Notifications.dnd ? Icons.bellOff : Icons.bell
                label: "Do not disturb"
                sublabel: (Notifications.dnd ? "On" : "Off")
                          + (Notifications.count > 0 ? "  ·  " + Notifications.count + " new" : "")
                active: Notifications.dnd
                onClicked: Notifications.toggle()
            }
        }
    }

    // ── Spec sheet ───────────────────────────────────────────────────
    Card {
        Layout.fillWidth: true
        Layout.topMargin: 4
        implicitHeight: specs.implicitHeight + 32
        shown: root.revealed
        order: 8

        GridLayout {
            id: specs
            anchors.fill: parent
            anchors.margins: 16
            columns: 3
            columnSpacing: 20
            rowSpacing: 12

            Spec { key: "kernel"; value: SystemInfo.kernel }
            Spec { key: "resolution"; value: SystemInfo.resolution }
            Spec { key: "compositor"; value: SystemInfo.compositor !== "" ? "Hyprland " + SystemInfo.compositor : "" }
            Spec {
                key: "network"
                value: Network.ethConnected ? "ethernet · " + Network.ethIp
                     : Network.ssid !== "" ? "wi-fi · " + Network.wifiIp : "offline"
            }
            Spec { key: "uptime"; value: SystemInfo.uptime }
            Spec { key: "wallpaper"; value: Wallpaper.current !== "" ? Wallpaper.fileName(Wallpaper.current) : "" }
        }
    }

    // ── Building blocks ──────────────────────────────────────────────

    // Base card: slides up + fades in (staggered by `order`), lifts on hover
    component Card: Rectangle {
        id: card
        property bool shown: true
        property int order: 0
        property bool hoverable: true

        radius: Theme.radius + 2
        color: Theme.surface
        border.width: 1
        border.color: hoverable && cardHover.hovered
                      ? Qt.rgba(Theme.rose.r, Theme.rose.g, Theme.rose.b, 0.55) : Theme.border
        Behavior on border.color { ColorAnimation { duration: 180 } }

        scale: hoverable && cardHover.hovered ? 1.02 : 1
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        z: cardHover.hovered ? 1 : 0

        opacity: 0
        transform: Translate { id: slide; y: 22 }

        HoverHandler { id: cardHover }

        function enter() { leave.stop(); entrance.restart(); }
        onShownChanged: shown ? enter() : leave.restart()
        Component.onCompleted: if (shown) enter()

        SequentialAnimation {
            id: entrance
            PauseAnimation { duration: card.order * 70 }
            ParallelAnimation {
                NumberAnimation { target: card; property: "opacity"; to: 1; duration: 450; easing.type: Easing.OutCubic }
                NumberAnimation { target: slide; property: "y"; to: 0; duration: 650; easing.type: Easing.OutBack; easing.overshoot: 1.6 }
            }
        }
        ParallelAnimation {
            id: leave
            NumberAnimation { target: card; property: "opacity"; to: 0; duration: 1 }
            NumberAnimation { target: slide; property: "y"; to: 22; duration: 1 }
        }
    }

    component Kicker: Text {
        color: Theme.muted
        font.family: Theme.font
        font.pixelSize: 9
        font.letterSpacing: 1.8
        font.capitalization: Font.AllUppercase
    }

    // Number that eases toward its target instead of jumping
    component CountUp: Text {
        id: countUp
        property real target: 0
        property real current: target
        Behavior on current { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
        text: Math.round(current)
        color: Theme.text
        font.family: Theme.serif
    }

    component Chip: Rectangle {
        property alias text: chipText.text
        implicitWidth: chipText.implicitWidth + 18
        implicitHeight: 22
        radius: 11
        color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.5)
        border.width: 1
        border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.18)
        Text {
            id: chipText
            anchors.centerIn: parent
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 10
        }
    }

    // Smooth area graph
    component Graph: Canvas {
        id: graph
        property var points: []
        property color line: Theme.rose
        onPointsChanged: requestPaint()
        onLineChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const p = points;
            if (!p || p.length < 2) return;
            const step = width / 47;
            const x0 = width - (p.length - 1) * step;
            const y = v => height - 2 - Math.max(0, Math.min(1, v)) * (height - 12);

            ctx.beginPath();
            ctx.moveTo(x0, y(p[0]));
            for (let i = 1; i < p.length; i++) {
                const xa = x0 + (i - 1) * step, xb = x0 + i * step, xm = (xa + xb) / 2;
                ctx.bezierCurveTo(xm, y(p[i - 1]), xm, y(p[i]), xb, y(p[i]));
            }
            ctx.strokeStyle = line;
            ctx.lineWidth = 2;
            ctx.stroke();

            // Glowing head on the newest point
            const hx = x0 + (p.length - 1) * step, hy = y(p[p.length - 1]);

            ctx.lineTo(width, height);
            ctx.lineTo(x0, height);
            ctx.closePath();
            const g = ctx.createLinearGradient(0, 0, 0, height);
            g.addColorStop(0, Qt.rgba(line.r, line.g, line.b, 0.40));
            g.addColorStop(1, Qt.rgba(line.r, line.g, line.b, 0.0));
            ctx.fillStyle = g;
            ctx.fill();

            ctx.beginPath();
            ctx.arc(hx - 2, hy, 6, 0, Math.PI * 2);
            ctx.fillStyle = Qt.rgba(line.r, line.g, line.b, 0.25);
            ctx.fill();
            ctx.beginPath();
            ctx.arc(hx - 2, hy, 3, 0, Math.PI * 2);
            ctx.fillStyle = line;
            ctx.fill();
        }
    }

    // Glowing ring gauge card
    component Gauge: Card {
        id: gauge
        property string label: ""
        property real value: 0          // 0..1, -1 = no ring
        property string text: ""
        property string sub: ""
        property bool hot: false

        Layout.fillWidth: true
        Layout.preferredWidth: 1
        implicitHeight: 128

        Kicker {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: 12
            text: gauge.label
        }

        Canvas {
            id: ring
            width: 66
            height: 66
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 2
            visible: gauge.value >= 0

            property real shown: Math.max(0, gauge.value)
            property color track: Theme.surface2
            property color fill: gauge.hot ? Theme.danger : Theme.rose
            Behavior on shown { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
            onShownChanged: requestPaint()
            onFillChanged: requestPaint()
            onTrackChanged: requestPaint()

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: ring.fill
                shadowBlur: 0.8
                shadowOpacity: 0.7
                shadowHorizontalOffset: 0
                shadowVerticalOffset: 0
            }

            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const c = width / 2, r = c - 6;
                const start = Math.PI * 0.75, span = Math.PI * 1.5;
                ctx.lineCap = "round";
                ctx.lineWidth = 5;
                ctx.strokeStyle = track;
                ctx.beginPath();
                ctx.arc(c, c, r, start, start + span);
                ctx.stroke();
                ctx.strokeStyle = fill;
                ctx.beginPath();
                ctx.arc(c, c, r, start, start + span * Math.max(0.001, shown));
                ctx.stroke();
            }
        }

        Text {
            anchors.centerIn: gauge.value >= 0 ? ring : parent
            text: gauge.text
            color: gauge.hot ? Theme.danger : Theme.text
            font.family: Theme.serif
            font.pixelSize: gauge.value >= 0 ? 19 : 26
        }

        Text {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 10
            horizontalAlignment: Text.AlignHCenter
            text: gauge.sub
            color: Theme.subtext
            font.family: Theme.font
            font.pixelSize: 10
            elide: Text.ElideRight
        }
    }

    component Spec: ColumnLayout {
        id: spec
        property string key: ""
        property string value: ""
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        spacing: 2
        Kicker { text: spec.key }
        Text {
            Layout.fillWidth: true
            text: spec.value !== "" ? spec.value : "—"
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 1
            elide: Text.ElideRight
        }
    }
}
