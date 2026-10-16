pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Pengaturan desktop widget yang bisa diubah dari halaman Widgets.
// Nilai awal dari Config.qml, lalu disimpan ke Config.widgetStateFile (JSON)
// sehingga tetap berlaku setelah restart.
Singleton {
    id: root

    // ── GitHub ───────────────────────────────────────────────────────
    property bool githubShown: Config.githubWidget
    property string githubPosition: Config.githubPosition
    property string githubScreen: Config.githubScreen
    property bool githubCard: Config.githubCardBackground
    property int githubCell: Config.githubCellSize
    property real githubOpacity: 0.92

    // ── Jam desktop ──────────────────────────────────────────────────
    property bool clockShown: Config.clockWidget
    property string clockPosition: Config.clockPosition
    property string clockScreen: ""
    property bool clockCard: false
    property real clockOpacity: 0.85
    property int clockSize: 84
    property bool clockSeconds: false
    property bool clockStats: true

    // Daftar properti yang disimpan
    readonly property var keys: ["githubShown", "githubPosition", "githubScreen",
                                 "githubCard", "githubCell", "githubOpacity",
                                 "clockShown", "clockPosition", "clockScreen", "clockCard",
                                 "clockOpacity", "clockSize", "clockSeconds", "clockStats"]

    property bool loaded: false

    function reset() {
        githubShown = Config.githubWidget;
        githubPosition = Config.githubPosition;
        githubScreen = Config.githubScreen;
        githubCard = Config.githubCardBackground;
        githubCell = Config.githubCellSize;
        githubOpacity = 0.92;
        clockShown = Config.clockWidget;
        clockPosition = Config.clockPosition;
        clockScreen = "";
        clockCard = false;
        clockOpacity = 0.85;
        clockSize = 84;
        clockSeconds = false;
        clockStats = true;
    }

    // Simpan 400 ms setelah perubahan terakhir
    onGithubShownChanged: saveTimer.restart()
    onGithubPositionChanged: saveTimer.restart()
    onGithubScreenChanged: saveTimer.restart()
    onGithubCardChanged: saveTimer.restart()
    onGithubCellChanged: saveTimer.restart()
    onGithubOpacityChanged: saveTimer.restart()
    onClockShownChanged: saveTimer.restart()
    onClockPositionChanged: saveTimer.restart()
    onClockScreenChanged: saveTimer.restart()
    onClockCardChanged: saveTimer.restart()
    onClockOpacityChanged: saveTimer.restart()
    onClockSizeChanged: saveTimer.restart()
    onClockSecondsChanged: saveTimer.restart()
    onClockStatsChanged: saveTimer.restart()

    Timer {
        id: saveTimer
        interval: 400
        onTriggered: {
            if (!root.loaded) return;
            const obj = {};
            for (const k of root.keys) obj[k] = root[k];
            saveProc.command = ["sh", "-c", 'mkdir -p "$(dirname "$2")" && printf "%s\\n" "$1" > "$2"',
                                "sh", JSON.stringify(obj, null, 2), Config.widgetStateFile];
            saveProc.running = true;
        }
    }

    Process { id: saveProc }

    FileView {
        path: Config.widgetStateFile
        printErrors: false
        onLoaded: {
            try {
                const obj = JSON.parse(text());
                for (const k of root.keys) if (obj[k] !== undefined) root[k] = obj[k];
            } catch (e) {}
            root.loaded = true;
        }
        onLoadFailed: root.loaded = true      // file belum ada: pakai default dari Config
    }
}
