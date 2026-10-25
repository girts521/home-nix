import QtQuick

BarPanel {
    id: panel
    required property var sys

    bg: sys.bg; fg: sys.fg; accent: sys.accent; secondary: sys.secondary
    panelWidth: 320

    readonly property real usedFrac: sys.ramTotalGb > 0 ? sys.ramUsedGb / sys.ramTotalGb : 0
    readonly property real cacheFrac: sys.ramTotalGb > 0 ? sys.ramCachedGb / sys.ramTotalGb : 0
    readonly property real bufFrac: sys.ramTotalGb > 0 ? sys.ramBuffersGb / sys.ramTotalGb : 0

    // Header
    Item {
        width: parent.width
        height: 44
        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            Text { text: "▤"; color: panel.accent; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Text { text: "Memory"; color: panel.fg; font.bold: true; font.pixelSize: 13 }
                Text { text: "RAM · " + sys.ramTotalGb.toFixed(0) + " GB"; color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.6); font.pixelSize: 10 }
            }
        }
        Column {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            Text {
                anchors.right: parent.right
                text: Math.round(panel.usedFrac * 100) + "%"
                color: panel.accent; font.bold: true; font.pixelSize: 20; font.family: "monospace"
            }
            Text {
                anchors.right: parent.right
                text: sys.ramUsedGb.toFixed(1) + " / " + sys.ramTotalGb.toFixed(0) + " GB"
                color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.6); font.pixelSize: 10; font.family: "monospace"
            }
        }
    }

    // Stacked usage bar: used | buffers | cache
    Column {
        width: parent.width
        spacing: 4
        Rectangle {
            width: parent.width
            height: 12
            radius: 6
            color: sys.dark
            border.width: 1
            border.color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.1)
            clip: true

            Row {
                anchors.fill: parent
                Rectangle { width: parent.width * panel.usedFrac; height: parent.height; color: panel.accent }
                Rectangle { width: parent.width * panel.bufFrac; height: parent.height; color: "#38bdf8" }
                Rectangle { width: parent.width * panel.cacheFrac; height: parent.height; color: panel.secondary }
            }
        }
        Row {
            width: parent.width
            Text { width: parent.width / 3; text: "■ Used " + sys.ramUsedGb.toFixed(1) + "G"; color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.7); font.pixelSize: 10; font.family: "monospace" }
            Text { width: parent.width / 3; text: "■ Buffers " + sys.ramBuffersGb.toFixed(1) + "G"; color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.7); font.pixelSize: 10; font.family: "monospace" }
            Text { width: parent.width / 3; text: "■ Cache " + sys.ramCachedGb.toFixed(1) + "G"; color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.7); font.pixelSize: 10; font.family: "monospace" }
        }
    }

    // Stats
    Row {
        width: parent.width
        spacing: 6
        Repeater {
            model: [
                { k: "AVAILABLE", v: sys.ramAvailGb.toFixed(1) + " GB" },
                { k: "SWAP", v: sys.swapUsedGb.toFixed(1) + " / " + sys.swapTotalGb.toFixed(0) + " GB" },
                { k: "PRESSURE", v: panel.usedFrac > 0.85 ? "High" : (panel.usedFrac > 0.6 ? "Medium" : "Low") }
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
