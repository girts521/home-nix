import Quickshell
import Quickshell.Io
import QtQuick

BarPanel {
    id: panel
    required property var sys

    bg: sys.bg
    fg: sys.fg
    dark: sys.dark
    accent: sys.accent
    secondary: sys.secondary
    panelWidth: 320
    contentInset: 16
    contentSpacing: 12
    cornerRadius: 12

    readonly property real total: Math.max(0, sys.ramTotalGb)
    readonly property real usedFrac: total > 0 ? Math.min(1, sys.ramUsedGb / total) : 0
    readonly property real activeGb: Math.max(0, sys.ramUsedGb - sys.ramBuffersGb - sys.ramCachedGb)
    readonly property real activeFrac: total > 0 ? Math.min(1, activeGb / total) : 0
    readonly property real bufFrac: total > 0 ? Math.min(1 - activeFrac, sys.ramBuffersGb / total) : 0
    readonly property real cacheFrac: total > 0 ? Math.min(1 - activeFrac - bufFrac, sys.ramCachedGb / total) : 0
    property var topProcesses: []

    function readProcesses(text) {
        const rows = [];
        for (const line of text.trim().split("\n").slice(1)) {
            const fields = line.trim().split(/\s+/);
            if (fields.length >= 2) {
                const mb = Number(fields[fields.length - 1]) / 1024;
                const value = mb >= 1024 ? (mb / 1024).toFixed(1) + " GB" : (mb >= 1 ? mb.toFixed(0) + " MB" : (mb * 1024).toFixed(0) + " KB");
                rows.push({ name: fields.slice(0, -1).join(" "), value: value });
            }
        }
        topProcesses = rows.slice(0, 3);
    }

    Process {
        id: processList
        command: ["sh", "-c", "ps -eo comm,rss --sort=-rss | head -n 4"]
        running: true
        stdout: StdioCollector { onStreamFinished: panel.readProcesses(this.text) }
    }
    Timer { interval: 10000; running: true; repeat: true; onTriggered: processList.running = true }

    Item {
        width: parent.width
        height: 42
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.1)
        }
        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -4
            spacing: 6
            Icon { name: "memory-stick"; tone: "accent"; size: 16 }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Text { text: "Memory"; color: panel.fg; font.bold: true; font.pixelSize: 13; font.family: panel.uiFont }
                Text { text: "RAM · " + panel.total.toFixed(0) + " GB"; color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.6); font.pixelSize: 10; font.family: panel.uiFont }
            }
        }
        Column {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -4
            Text { anchors.right: parent.right; text: Math.round(panel.usedFrac * 100) + "%"; color: panel.accent; font.bold: true; font.pixelSize: 18; font.family: "monospace" }
            Text { anchors.right: parent.right; text: sys.ramUsedGb.toFixed(1) + " / " + panel.total.toFixed(0) + " GB"; color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.6); font.pixelSize: 10; font.family: "monospace" }
        }
    }

    Column {
        width: parent.width
        spacing: 4
        Rectangle {
            width: parent.width
            height: 12
            radius: 6
            color: panel.dark
            border.width: 1
            border.color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.1)
            clip: true
            Row {
                anchors.fill: parent
                Rectangle { width: parent.width * panel.activeFrac; height: parent.height; color: panel.accent }
                Rectangle { width: parent.width * panel.bufFrac; height: parent.height; color: "#38bdf8" }
                Rectangle { width: parent.width * panel.cacheFrac; height: parent.height; color: Qt.rgba(panel.secondary.r, panel.secondary.g, panel.secondary.b, 0.6) }
            }
        }
        Row {
            width: parent.width
            Row {
                width: parent.width / 3
                spacing: 3
                Rectangle { width: 8; height: 8; radius: 2; color: panel.accent; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "Used " + panel.activeGb.toFixed(1) + "G"; color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.7); font.pixelSize: 10; font.family: "monospace" }
            }
            Row {
                width: parent.width / 3
                spacing: 3
                Rectangle { width: 8; height: 8; radius: 2; color: "#38bdf8"; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "Buffers " + sys.ramBuffersGb.toFixed(1) + "G"; color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.7); font.pixelSize: 10; font.family: "monospace" }
            }
            Row {
                width: parent.width / 3
                spacing: 3
                Rectangle { width: 8; height: 8; radius: 2; color: Qt.rgba(panel.secondary.r, panel.secondary.g, panel.secondary.b, 0.6); anchors.verticalCenter: parent.verticalCenter }
                Text { text: "Cache " + sys.ramCachedGb.toFixed(1) + "G"; color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.7); font.pixelSize: 10; font.family: "monospace" }
            }
        }
    }

    Row {
        width: parent.width
        spacing: 8
        Repeater {
            model: [
                { k: "AVAILABLE", v: sys.ramAvailGb.toFixed(1) + " GB" },
                { k: "SWAP", v: sys.swapUsedGb.toFixed(1) + " / " + sys.swapTotalGb.toFixed(0) + " GB" },
                { k: "PRESSURE", v: panel.usedFrac > 0.85 ? "High" : (panel.usedFrac > 0.6 ? "Medium" : "Low") }
            ]
            Rectangle {
                required property var modelData
                width: (parent.width - 16) / 3
                height: 36
                radius: 8
                color: Qt.rgba(panel.dark.r, panel.dark.g, panel.dark.b, 0.5)
                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    Text { text: modelData.k; color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.5); font.pixelSize: 10; font.family: "monospace" }
                    Text { text: modelData.v; color: modelData.k === "PRESSURE" && panel.usedFrac < 0.6 ? "#34d399" : panel.fg; font.pixelSize: 10; font.family: "monospace" }
                }
            }
        }
    }

    Column {
        width: parent.width
        spacing: 4
        Text { text: "TOP PROCESSES"; color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.5); font.pixelSize: 10; font.bold: true; font.family: panel.uiFont }
        Repeater {
            model: panel.topProcesses
            Item {
                required property var modelData
                width: parent.width
                height: 28
                Text { anchors.left: parent.left; anchors.leftMargin: 6; anchors.verticalCenter: parent.verticalCenter; text: modelData.name; color: panel.fg; font.pixelSize: 12; font.family: panel.uiFont; elide: Text.ElideRight; width: parent.width - 76 }
                Text { anchors.right: parent.right; anchors.rightMargin: 6; anchors.verticalCenter: parent.verticalCenter; text: modelData.value; color: panel.accent; font.pixelSize: 12; font.family: "monospace" }
            }
        }
    }
}
