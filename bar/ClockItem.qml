// Jam di bar + kalender popup.
//   klik kanan  : buka/tutup kalender
//   hover       : kalender muncul setelah jeda singkat (matikan: Config.calendarOnHover)
//   klik kiri   : `clicked()` (diatur di Module.qml)

import QtQuick
import qs.config

BarItem {
    id: root

    required property var barWindow
    property string format: "hh:mm"

    // pinned = dibuka lewat klik kanan, tidak ditutup oleh mouse leave
    property bool pinned: false

    label: Qt.formatDateTime(BarState.clock.date, format)

    function openCal()  { calendar.visible = true; }
    function closeCal() { calendar.visible = false; pinned = false; }

    onRightClicked: {
        if (calendar.visible && pinned) closeCal();
        else { pinned = true; openCal(); }
    }

    // Hover: buka setelah 400 ms, tutup 300 ms setelah mouse keluar dari jam & kalender
    HoverHandler { id: hover }

    readonly property bool anyHover: hover.hovered || calendar.hovered

    onAnyHoverChanged: {
        if (anyHover) {
            closeTimer.stop();
            if (Config.calendarOnHover && !calendar.visible) openTimer.restart();
        } else {
            openTimer.stop();
            if (!pinned) closeTimer.restart();
        }
    }

    Timer { id: openTimer;  interval: 400; onTriggered: root.openCal() }
    Timer { id: closeTimer; interval: 300; onTriggered: if (!root.pinned) root.closeCal() }

    CalendarPopup {
        id: calendar
        barWindow: root.barWindow
        target: root
        visible: false
    }
}
