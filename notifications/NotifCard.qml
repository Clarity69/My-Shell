// Kartu satu notifikasi. Dipakai popup dan pusat notifikasi.
//   compact: true = versi daftar (tanpa timer, tanpa bayangan)

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.config
import qs.components
import qs.services

Rectangle {
    id: card

    required property var notif
    property bool compact: false
    property int refreshTick: 0          // dinaikkan berkala agar label waktu diperbarui

    // Popup: hilang sendiri setelah timeout, jeda saat di-hover
    readonly property bool critical: notif && notif.urgency === NotificationUrgency.Critical
    readonly property int timeout: !notif ? 0
        : notif.expireTimeout > 0 ? notif.expireTimeout
        : critical ? 0 : Config.notifTimeout
    property real progress: 1
    signal expired()

    readonly property string image: notif ? Notifications.iconSource(notif.image) : ""
    readonly property string appIcon: notif ? Notifications.iconSource(notif.appIcon) : ""

    implicitHeight: col.implicitHeight + 24
    radius: Theme.radius
    color: compact ? (hover.hovered ? Theme.surface : "transparent") : Theme.bg
    border.width: compact ? 0 : 1
    border.color: critical ? Theme.danger : Theme.border
    Behavior on color { ColorAnimation { duration: 120 } }

    HoverHandler { id: hover }

    // Hitung mundur popup
    NumberAnimation on progress {
        id: countdown
        running: !card.compact && card.timeout > 0
        paused: hover.hovered
        from: 1; to: 0
        duration: card.timeout
        onFinished: card.expired()
    }

    // Klik badan kartu = aksi default
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton) Notifications.dismiss(card.notif);
            else Notifications.activate(card.notif);
        }
    }

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Gambar notifikasi (mis. avatar) atau ikon aplikasi
            Item {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                Layout.alignment: Qt.AlignTop

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radiusSmall
                    color: Theme.surface
                    visible: card.image === "" && card.appIcon === ""

                    Text {
                        anchors.centerIn: parent
                        text: Icons.bell
                        color: Theme.subtext
                        font.family: Theme.font
                        font.pixelSize: 20
                    }
                }

                ClippingRectangle {
                    anchors.fill: parent
                    radius: Theme.radiusSmall
                    color: "transparent"
                    visible: card.image !== ""

                    Image {
                        anchors.fill: parent
                        source: card.image
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }

                IconImage {
                    visible: card.image === "" && card.appIcon !== ""
                    anchors.fill: parent
                    anchors.margins: 4
                    source: card.appIcon
                }

                // Ikon aplikasi kecil di sudut kalau ada gambar
                IconImage {
                    visible: card.image !== "" && card.appIcon !== ""
                    width: 16; height: 16
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: -4
                    source: card.appIcon
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        Layout.fillWidth: true
                        text: card.notif ? (card.notif.appName || "Notification") : ""
                        color: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: 10
                        font.letterSpacing: 1
                        font.capitalization: Font.AllUppercase
                        elide: Text.ElideRight
                    }
                    Text {
                        text: card.notif ? (card.refreshTick, Notifications.ago(card.notif.id)) : ""
                        color: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: 10
                    }
                    IconButton {
                        icon: Icons.close
                        size: 20
                        iconColor: Theme.muted
                        onClicked: Notifications.dismiss(card.notif)
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: card.notif ? card.notif.summary : ""
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    font.bold: true
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: card.notif ? card.notif.body : ""
                    textFormat: Text.StyledText
                    color: Theme.subtext
                    linkColor: Theme.rose
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 1
                    wrapMode: Text.Wrap
                    maximumLineCount: card.compact ? 2 : 4
                    elide: Text.ElideRight
                    onLinkActivated: link => Qt.openUrlExternally(link)
                }
            }
        }

        // Tombol aksi (selain "default")
        Flow {
            Layout.fillWidth: true
            Layout.leftMargin: 52
            spacing: 6
            visible: actionRepeater.count > 0

            Repeater {
                id: actionRepeater
                model: Notifications.actionsOf(card.notif).filter(a => a.identifier !== "default")

                TextButton {
                    required property var modelData
                    text: modelData.text
                    onClicked: Notifications.invoke(card.notif, modelData)
                }
            }
        }
    }

    // Bilah sisa waktu popup
    Rectangle {
        visible: !card.compact && card.timeout > 0
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.leftMargin: card.radius
        height: 2
        radius: 1
        width: (parent.width - card.radius * 2) * card.progress
        color: card.critical ? Theme.danger : Theme.subtext
        opacity: 0.5
    }
}
