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

    property real readRate: 0
    property real writeRate: 0
    property var previousIo: null

    function orderedDisks() {
        const priority = { "/": 0, "/home": 1, "/data": 2, "/boot/efi": 3 };
        return (sys.disks || []).slice().sort((a, b) => {
            const aOrder = priority[a.mount] === undefined ? 4 : priority[a.mount];
            const bOrder = priority[b.mount] === undefined ? 4 : priority[b.mount];
            return aOrder - bOrder || a.mount.localeCompare(b.mount);
        });
    }

    function updateIo(text) {
        let readSectors = 0;
        let writeSectors = 0;
        for (const line of text.trim().split("\n")) {
            const fields = line.trim().split(/\s+/);
            if (fields.length < 10) continue;
            const name = fields[2];
            if (/^(loop|ram|zram)/.test(name)) continue;
            // /proc/diskstats lists partitions as well as whole devices; count
            // only whole-device counters so their sectors are not counted twice.
            if (/^(sd[a-z]+|vd[a-z]+|xvd[a-z]+|hd[a-z]+)\d+$/.test(name) || /^(nvme\d+n\d+p\d+|mmcblk\d+p\d+)$/.test(name)) continue;
            // Device-mapper and RAID counters can duplicate the backing disks.
            if (/^(dm-\d+|md\d+)$/.test(name)) continue;
            readSectors += Number(fields[5]) || 0;
            writeSectors += Number(fields[9]) || 0;
        }
        const current = { read: readSectors, write: writeSectors, at: Date.now() };
        if (previousIo) {
            const elapsed = Math.max(1, current.at - previousIo.at) / 1000;
            readRate = Math.max(0, current.read - previousIo.read) * 512 / elapsed / 1048576;
            writeRate = Math.max(0, current.write - previousIo.write) * 512 / elapsed / 1048576;
        }
        previousIo = current;
    }

    Process {
        id: ioStats
        command: ["cat", "/proc/diskstats"]
        running: true
        stdout: StdioCollector { onStreamFinished: panel.updateIo(this.text) }
    }
    Timer { interval: 2000; running: true; repeat: true; onTriggered: ioStats.running = true }

    Item {
        width: parent.width
        height: 33
        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            Icon { name: "hard-drive"; tone: "accent"; size: 16 }
            Text { text: "Disk Usage"; color: panel.fg; font.bold: true; font.pixelSize: 13; font.family: panel.uiFont }
        }
        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: sys.disks.length + " volumes"
            color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.6)
            font.pixelSize: 10
            font.family: "monospace"
        }
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.1)
        }
    }

    Column {
        width: parent.width
        spacing: 12
        Repeater {
            model: panel.orderedDisks()
            Column {
                required property var modelData
                width: parent.width
                spacing: 4
                Item {
                    id: row
                    width: parent.width
                    height: 16
                    Text {
                        id: usage
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.usedHuman + " / " + modelData.sizeHuman
                        color: modelData.percent > 75 ? "#fbbf24" : panel.fg
                        font.pixelSize: 12
                        font.family: "monospace"
                    }
                    Row {
                        anchors.left: parent.left
                        anchors.right: usage.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        Text {
                            id: mountLabel
                            text: modelData.mount
                            color: panel.fg
                            font.bold: true
                            font.pixelSize: 12
                            font.family: panel.uiFont
                            elide: Text.ElideRight
                            width: Math.min(implicitWidth, Math.max(0, parent.width * 0.55))
                        }
                        Text {
                            text: modelData.device.split("/").pop()
                            color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.5)
                            font.pixelSize: 10
                            font.family: panel.uiFont
                            elide: Text.ElideRight
                            width: Math.max(0, parent.width - mountLabel.width - parent.spacing)
                        }
                    }
                }
                Rectangle {
                    width: parent.width
                    height: 6
                    radius: 3
                    color: Qt.rgba(1, 1, 1, 0.08)
                    clip: true
                    Rectangle {
                        height: parent.height
                        radius: 3
                        width: parent.width * Math.max(0, Math.min(100, modelData.percent)) / 100
                        color: modelData.percent > 75 ? "#fbbf24" : panel.accent
                        Behavior on width { NumberAnimation { duration: 600 } }
                    }
                }
            }
        }
    }

    Column {
        width: parent.width
        spacing: 8
        Rectangle { width: parent.width; height: 1; color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.1) }
        Row {
            width: parent.width
            spacing: 8
            Rectangle {
                width: (parent.width - 8) / 2
                height: 36
                radius: 8
                color: Qt.rgba(panel.dark.r, panel.dark.g, panel.dark.b, 0.5)
                Column {
                    anchors.left: parent.left; anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    Text { text: "READ"; color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.5); font.pixelSize: 10; font.family: "monospace" }
                    Text { text: panel.readRate.toFixed(1) + " MB/s"; color: panel.fg; font.pixelSize: 10; font.family: "monospace" }
                }
            }
            Rectangle {
                width: (parent.width - 8) / 2
                height: 36
                radius: 8
                color: Qt.rgba(panel.dark.r, panel.dark.g, panel.dark.b, 0.5)
                Column {
                    anchors.left: parent.left; anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    Text { text: "WRITE"; color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.5); font.pixelSize: 10; font.family: "monospace" }
                    Text { text: panel.writeRate.toFixed(1) + " MB/s"; color: panel.fg; font.pixelSize: 10; font.family: "monospace" }
                }
            }
        }
    }
}
