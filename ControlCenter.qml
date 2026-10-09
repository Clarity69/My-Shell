// Window settings: sidebar navigasi + halaman di kanan.
// FloatingWindow = window aplikasi biasa (xdg-toplevel), bukan panel layer-shell.

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.components
import qs.pages

FloatingWindow {
    id: root

    title: "Control Center"     // dipakai windowrule Hyprland
    visible: false

    implicitWidth: Theme.windowWidth
    implicitHeight: Theme.windowHeight
    color: Theme.bg

    property int page: 0
    function toggle() { visible = !visible; }

    // Urutan di sini = urutan StackLayout di bawah. `keywords` dipakai pencarian.
    readonly property var pages: [
        { label: "Profile",    section: "overview", num: "01", keywords: "system cpu memory temp telemetry quick" },
        { label: "Network",    section: "devices",  num: "02", keywords: "wifi wi-fi ethernet lan internet ip kabel" },
        { label: "Bluetooth",  section: "devices",  num: "02", keywords: "headset earbuds pair device" },
        { label: "Sound",      section: "devices",  num: "02", keywords: "audio volume speaker mic microphone output input" },
        { label: "Display",    section: "devices",  num: "02", keywords: "brightness night light screen resolution hyprsunset" },
        { label: "Appearance", section: "look",     num: "03", keywords: "pywal theme colors gaps rounding blur animation notification dnd" },
        { label: "Wallpaper",  section: "look",     num: "03", keywords: "awww swww background image pywal" },
        { label: "Power",      section: "system",   num: "04", keywords: "battery profile lock suspend logout reboot shutdown" },
        { label: "Keybinds",   section: "system",   num: "04", keywords: "shortcuts keys bind hotkey" }
    ]

    function isActive(i) { return root.visible && root.page === i; }

    // Buka langsung ke halaman tertentu, mis. "network" atau "sound".
    // Kalau halaman itu sudah terbuka, window ditutup (perilaku toggle).
    function openPage(name) {
        const i = pages.findIndex(p => p.label.toLowerCase() === name.toLowerCase());
        if (i < 0) { visible = true; return; }
        if (visible && page === i) { visible = false; return; }
        page = i;
        visible = true;
    }

    onVisibleChanged: if (visible) { fadeIn.restart(); body.forceActiveFocus(); }

    // Kalau window ditutup dari luar (mis. killactive di Hyprland), samakan status
    // `visible` supaya toggle berikutnya langsung membuka, bukan "menutup" dulu.
    Connections {
        target: root
        ignoreUnknownSignals: true
        function onClosed() { root.visible = false; }
    }

    Item {
        id: body
        anchors.fill: parent
        focus: true

        // Esc = hapus pencarian / tutup · Ctrl+1..9 = halaman · Ctrl+F = cari
        Keys.onPressed: event => {
            const ctrl = event.modifiers & Qt.ControlModifier;
            if (event.key === Qt.Key_Escape) {
                if (sidebar.query !== "") sidebar.query = "";
                else root.visible = false;
                event.accepted = true;
            } else if (ctrl && event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                const i = event.key - Qt.Key_1;
                if (i < root.pages.length) root.page = i;
                event.accepted = true;
            } else if (ctrl && event.key === Qt.Key_F) {
                sidebar.focusSearch();
                event.accepted = true;
            }
        }

        NumberAnimation {
            id: fadeIn
            target: body; property: "opacity"
            from: 0; to: 1; duration: 180; easing.type: Easing.OutCubic
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            Sidebar {
                id: sidebar
                Layout.fillHeight: true
                Layout.preferredWidth: Theme.sidebarWidth
                pages: root.pages
                current: root.page
                onSelected: i => { root.page = i; body.forceActiveFocus(); }
            }

            Rectangle {
                Layout.fillHeight: true
                implicitWidth: 1
                color: Theme.border
            }

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: 28
                Layout.bottomMargin: 20
                Layout.leftMargin: 28
                Layout.rightMargin: 14
                currentIndex: root.page

                OverviewPage   { active: root.isActive(0) }
                NetworkPage    { active: root.isActive(1) }
                BluetoothPage  { active: root.isActive(2) }
                SoundPage      { active: root.isActive(3) }
                DisplayPage    { active: root.isActive(4) }
                AppearancePage { active: root.isActive(5) }
                WallpaperPage  { active: root.isActive(6) }
                PowerPage      { active: root.isActive(7); onActionTriggered: root.visible = false }
                KeybindsPage   { active: root.isActive(8) }
            }
        }
    }
}
