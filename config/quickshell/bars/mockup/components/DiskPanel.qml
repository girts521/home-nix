import QtQuick

BarPanel {
    id: panel
    required property var sys

    bg: sys.bg; fg: sys.fg; accent: sys.accent; secondary: sys.secondary
    panelWidth: 320

    // Header
    Item {
        width: parent.width
        height: 30
        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            Text { text: "⛁"; color: panel.accent; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter }
            Text { text: "Disk Usage"; color: panel.fg; font.bold: true; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
        }
        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: sys.disks.length + " volumes"
            color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.6); font.pixelSize: 10; font.family: "monospace"
        }
    }

    Column {
        width: parent.width
        spacing: 12
        Repeater {
            model: sys.disks
            Column {
                required property var modelData
                width: parent.width
                spacing: 4

                Item {
                    width: parent.width
                    height: 16
                    Text {
                        anchors.left: parent.left
                        text: modelData.mount + "  "
                        color: panel.fg; font.bold: true; font.pixelSize: 12
                    }
                    Text {
                        anchors.right: parent.right
                        text: modelData.usedHuman + " / " + modelData.sizeHuman
                        color: modelData.percent > 75 ? "#fbbf24" : panel.fg
                        font.pixelSize: 11; font.family: "monospace"
                    }
                }
                Rectangle {
                    width: parent.width
                    height: 6
                    radius: 3
                    color: Qt.rgba(0.04, 0.08, 0.2, 1)
                    Rectangle {
                        height: parent.height
                        radius: 3
                        width: parent.width * modelData.percent / 100
                        color: modelData.percent > 75 ? "#fbbf24" : panel.accent
                        Behavior on width { NumberAnimation { duration: 600 } }
                    }
                }
                Text {
                    text: modelData.device
                    color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.5); font.pixelSize: 9; font.family: "monospace"
                }
            }
        }
    }
}
