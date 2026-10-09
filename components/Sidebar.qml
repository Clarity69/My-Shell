// Kolom kiri: brand, pencarian, navigasi berkelompok.
// `pages` = [{ label, section, num, keywords }] dari ControlCenter.qml.

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

Rectangle {
    id: root

    property int current: 0
    property var pages: []
    property alias query: search.text

    signal selected(int index)

    function focusSearch() { search.forceFocus(); }

    function matches(p) {
        const q = query.trim().toLowerCase();
        return q === "" || (p.label + " " + p.section + " " + p.keywords).toLowerCase().includes(q);
    }

    function firstMatch() {
        for (let i = 0; i < pages.length; i++) if (matches(pages[i])) return i;
        return -1;
    }

    color: Theme.bgAlt

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 2

        // Brand
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 54
            radius: Theme.radiusSmall
            color: "transparent"
            border.color: Theme.border

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                Text {
                    text: SystemInfo.host.charAt(0).toUpperCase()
                    color: Theme.text
                    font.family: Theme.serif
                    font.pixelSize: 26
                }

                ColumnLayout {
                    spacing: 0
                    Text {
                        text: "CONTROL"
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: 12
                        font.letterSpacing: 2
                    }
                    Text {
                        text: "settings"
                        color: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: 10
                        font.letterSpacing: 1
                    }
                }
            }
        }

        InputField {
            id: search
            Layout.topMargin: 12
            Layout.bottomMargin: 4
            icon: Icons.search
            placeholder: "Search…"
            onAccepted: {
                const i = root.firstMatch();
                if (i >= 0) root.selected(i);
            }
        }

        Repeater {
            model: root.pages

            ColumnLayout {
                id: entry
                required property var modelData
                required property int index

                readonly property bool firstOfSection:
                    index === 0 || root.pages[index - 1].section !== modelData.section

                Layout.fillWidth: true
                spacing: 2
                visible: root.matches(modelData) || (root.query === "" && firstOfSection)

                SectionLabel {
                    visible: root.query === "" && entry.firstOfSection
                    Layout.topMargin: entry.index === 0 ? 8 : 12
                    number: entry.modelData.num
                    text: entry.modelData.section
                }

                NavItem {
                    visible: root.matches(entry.modelData)
                    label: entry.modelData.label
                    hint: entry.index < 9 ? "^" + (entry.index + 1) : ""
                    active: root.current === entry.index
                    onClicked: root.selected(entry.index)
                }
            }
        }

        Item { Layout.fillHeight: true }

        Text {
            Layout.fillWidth: true
            text: root.query !== "" && root.firstMatch() < 0 ? "tidak ditemukan" : "esc · tutup   ^f · cari"
            color: Theme.muted
            font.family: Theme.font
            font.pixelSize: 10
            font.letterSpacing: 1
        }
    }
}
