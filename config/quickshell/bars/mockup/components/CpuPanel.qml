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

    property var topProcesses: []
    function readProcesses(text) {
        const rows = [];
        for (const line of text.trim().split("\n").slice(1)) {
            const fields = line.trim().split(/\s+/);
            if (fields.length >= 2)
                rows.push({ name: fields.slice(0, -1).join(" "), value: Number(fields[fields.length - 1]).toFixed(1) + "%" });
        }
        topProcesses = rows.slice(0, 3);
    }

    Process {
        id: processList
        command: ["sh", "-c", "ps -eo comm,pcpu --sort=-pcpu | head -n 4"]
        running: true
        stdout: StdioCollector { onStreamFinished: panel.readProcesses(this.text) }
    }
    Timer { interval: 5000; running: true; repeat: true; onTriggered: processList.running = true }

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
            Icon { name: "cpu"; tone: "accent"; size: 16 }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Text { text: "CPU"; color: panel.fg; font.bold: true; font.pixelSize: 13; font.family: panel.uiFont }
                Text { text: sys.cpuModel; color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.6); font.pixelSize: 10; font.family: panel.uiFont; elide: Text.ElideRight; width: 180 }
            }
        }
        Column {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -4
            Text { anchors.right: parent.right; text: sys.cpuPercent + "%"; color: panel.accent; font.bold: true; font.pixelSize: 18; font.family: "monospace" }
            Text { anchors.right: parent.right; text: sys.cpuTemp >= 0 ? sys.cpuTemp + "°C" : "temp n/a"; color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.6); font.pixelSize: 10; font.family: "monospace" }
        }
    }

    Column {
        width: parent.width
        spacing: 4
        Text { text: "PER CORE"; color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.5); font.pixelSize: 10; font.bold: true; font.family: panel.uiFont }
        Row {
            width: parent.width
            height: 64
            spacing: 4
            Repeater {
                model: sys.cpuCores
                Rectangle {
                    required property var modelData
                    width: Math.max(2, (parent.width - 4 * (sys.cpuCores.length - 1)) / Math.max(1, sys.cpuCores.length))
                    height: Math.max(4, parent.height * modelData / 100)
                    anchors.bottom: parent.bottom
                    radius: 2
                    color: Qt.rgba(panel.accent.r, panel.accent.g, panel.accent.b, 0.7)
                    Behavior on height { NumberAnimation { duration: 400 } }
                }
            }
        }
    }

    Row {
        width: parent.width
        spacing: 8
        Repeater {
            model: [
                { k: "LOAD 1/5/15", v: sys.cpuLoad },
                { k: "FREQ", v: sys.cpuFreq },
                { k: "UPTIME", v: sys.cpuUptime }
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
                    Text { text: modelData.v; color: panel.fg; font.pixelSize: 10; font.family: "monospace" }
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
                Text { anchors.left: parent.left; anchors.leftMargin: 6; anchors.verticalCenter: parent.verticalCenter; text: modelData.name; color: panel.fg; font.pixelSize: 12; font.family: panel.uiFont; elide: Text.ElideRight; width: parent.width - 60 }
                Text { anchors.right: parent.right; anchors.rightMargin: 6; anchors.verticalCenter: parent.verticalCenter; text: modelData.value; color: panel.accent; font.pixelSize: 12; font.family: "monospace" }
            }
        }
    }
}
