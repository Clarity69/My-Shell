pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs.config

// Daemon notifikasi (pengganti swaync). Quickshell memegang
// org.freedesktop.Notifications, jadi swaync / mako / dunst harus dimatikan.
//
//   list      : semua notifikasi (terbaru dulu), untuk pusat notifikasi
//   popups    : ListModel { nid } yang sedang tampil sebagai popup
//   dnd       : popup disembunyikan (kecuali critical), riwayat tetap tercatat
Singleton {
    id: root

    readonly property string daemon: "quickshell"
    readonly property bool available: true

    property bool dnd: false
    property bool centerOpen: false               // panel notifikasi di bawah bar

    function toggleCenter() { centerOpen = !centerOpen; }

    // Dynamic island (island/Island.qml) mengambil alih popup selama aktif
    property bool islandHandles: false
    signal arrived(var notification)

    // Saat panel dibuka, popup yang sedang tampil disingkirkan (sudah terlihat di panel)
    onCenterOpenChanged: if (centerOpen) popupModel.clear()
    property var times: ({})                      // id -> Date diterima
    property alias popups: popupModel

    readonly property var list: server.trackedNotifications.values.slice().reverse()
    readonly property int count: list.length

    // Dikelompokkan per aplikasi, kelompok dengan notifikasi terbaru di atas
    readonly property var groups: {
        const map = {};
        const order = [];
        for (const n of list) {
            const key = n.appName || "Unknown";
            if (!map[key]) { map[key] = { app: key, icon: n.appIcon, items: [] }; order.push(key); }
            map[key].items.push(n);
        }
        return order.map(k => map[k]);
    }

    // API lama tetap ada supaya bar & halaman lain tidak perlu banyak diubah
    function refresh() {}
    function toggle() { dnd = !dnd; saveDnd(); }

    function find(id) {
        return server.trackedNotifications.values.find(n => n.id === id) ?? null;
    }

    function hidePopup(id) {
        for (let i = popupModel.count - 1; i >= 0; i--)
            if (popupModel.get(i).nid === id) popupModel.remove(i);
    }

    function dismiss(n) { if (n) n.dismiss(); }

    function clearAll() {
        for (const n of server.trackedNotifications.values.slice()) n.dismiss();
        popupModel.clear();
    }

    function invoke(n, action) {
        action.invoke();
        if (!n.resident) n.dismiss();
    }

    // list<NotificationAction> -> array JS biasa
    function actionsOf(n) {
        const out = [];
        if (!n) return out;
        for (let i = 0; i < n.actions.length; i++) out.push(n.actions[i]);
        return out;
    }

    // Aksi "default" = klik badan notifikasi
    function activate(n) {
        if (!n) return;
        const a = actionsOf(n).find(x => x.identifier === "default");
        if (a) invoke(n, a); else hidePopup(n.id);
    }

    function iconSource(name) {
        if (!name) return "";
        if (name.startsWith("/")) return "file://" + name;
        if (name.includes("://")) return name;
        return Quickshell.iconPath(name, true);
    }

    function ago(id) {
        const t = times[id];
        if (!t) return "";
        const s = Math.floor((Date.now() - t.getTime()) / 1000);
        if (s < 60) return "now";
        if (s < 3600) return Math.floor(s / 60) + "m";
        if (s < 86400) return Math.floor(s / 3600) + "h";
        return Qt.formatDateTime(t, "dd MMM");
    }

    ListModel { id: popupModel }

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        actionsSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: n => {
            n.tracked = true;
            const t = Object.assign({}, root.times);
            t[n.id] = new Date();
            root.times = t;

            n.closed.connect(() => root.hidePopup(n.id));

            const critical = n.urgency === NotificationUrgency.Critical;
            if ((root.dnd || root.centerOpen) && !critical) return;

            root.arrived(n);
            if (root.islandHandles && !critical) return;

            root.hidePopup(n.id);                  // notifikasi yang diganti (replaces-id)
            popupModel.insert(0, { nid: n.id });
            while (popupModel.count > Config.notifMaxPopups) popupModel.remove(popupModel.count - 1);
        }
    }

    // ── DND disimpan supaya bertahan setelah restart ─────────────────
    function saveDnd() {
        saveProc.command = ["sh", "-c", 'mkdir -p "$(dirname "$2")" && printf "%s\\n" "$1" > "$2"',
                            "sh", dnd ? "1" : "0", Config.notifStateFile];
        saveProc.running = true;
    }

    Process { id: saveProc }

    FileView {
        path: Config.notifStateFile
        printErrors: false
        onLoaded: root.dnd = text().trim() === "1"
    }
}
