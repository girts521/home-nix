import QtQuick

BarPanel {
    id: panel
    required property var sys

    bg: sys.bg; fg: sys.fg; accent: sys.accent; secondary: sys.secondary
    panelWidth: 320

    // Header
    Item {
        width: parent.width
        height: 44
        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            Text { text: "⚙"; color: panel.accent; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Text { text: "CPU"; color: panel.fg; font.bold: true; font.pixelSize: 13 }
                Text { text: sys.cpuModel; color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.6); font.pixelSize: 10 }
            }
        }
        Column {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            Text {
                anchors.right: parent.right
                text: sys.cpuPercent + "%"
                color: panel.accent; font.bold: true; font.pixelSize: 20; font.family: "monospace"
            }
            Text {
                anchors.right: parent.right
                text: sys.cpuTemp >= 0 ? sys.cpuTemp + "°C" : "temp n/a"
                color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.6); font.pixelSize: 10; font.family: "monospace"
            }
        }
    }

    // Per-core bars
    Column {
        width: parent.width
        spacing: 4
        Text { text: "PER CORE"; color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.5); font.pixelSize: 10; font.bold: true }
        Row {
            width: parent.width
            height: 64
            spacing: 4
            Repeater {
                model: sys.cpuCores
                Rectangle {
                    required property var modelData
                    width: Math.max(2, (parent.width - 4 * (sys.cpuCores.length - 1)) / sys.cpuCores.length)
                    height: Math.max(4, parent.height * modelData / 100)
                    anchors.bottom: parent.bottom
                    radius: 3
                    color: Qt.rgba(panel.accent.r, panel.accent.g, panel.accent.b, 0.7)
                    Behavior on height { NumberAnimation { duration: 400 } }
                }
            }
        }
    }

    // Stats
    Row {
        width: parent.width
        spacing: 6
        Repeater {
            model: [
                { k: "LOAD 1/5/15", v: sys.cpuLoad },
                { k: "FREQ", v: sys.cpuFreq },
                { k: "UPTIME", v: sys.cpuUptime }
            ]
            Rectangle {
                required property var modelData
                width: (parent.width - 12) / 3
                height: 44
                radius: 8
                color: Qt.rgba(0.04, 0.08, 0.2, 0.5)
                Column {
                    anchors.left: parent.left; anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    Text { text: modelData.k; color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.5); font.pixelSize: 9; font.family: "monospace" }
                    Text { text: modelData.v; color: panel.fg; font.pixelSize: 10; font.family: "monospace" }
                }
            }
        }
    }
}
