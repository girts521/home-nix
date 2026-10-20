import Quickshell
import Quickshell.Io
import QtQuick
import QtQml.Models
import "components"

Scope {
    id: root

    // Pywal palette. The fallback colors are used until colors.json loads.
    property var wal: ({})
    property color bg: wal.special && wal.special.background
                       ? wal.special.background : "#122957"
    property color fg: wal.special && wal.special.foreground
                       ? wal.special.foreground : "#c6cff5"
    property color purple: wal.colors && wal.colors.color5
                           ? wal.colors.color5 : "#8e81d9"
    property color blue: wal.colors && wal.colors.color4
                         ? wal.colors.color4 : "#3f5ac8"

    property real cpuPercent: 0
    property real prevTotal: -1
    property real prevIdle: 0
    property string usedRam: "..."

    // Workspaces are received from niri's IPC event stream. They include the
    // output name, an index on that output, and per-output activation state.
    property var workspaces: []

    function handleNiriEvent(line) {
        try {
            const event = JSON.parse(line);
            if (event.WorkspacesChanged) {
                // Niri supplies the complete workspace list, including each output.
                root.workspaces = event.WorkspacesChanged.workspaces;
            } else if (event.WorkspaceActivated) {
                // Active changes are incremental, so update the shared array
                // and reassign it to refresh the QML workspace delegates.
                const change = event.WorkspaceActivated;
                const target = root.workspaces.find(w => w.id === change.id);
                if (!target) return;

                root.workspaces = root.workspaces.map(w => {
                    const updated = Object.assign({}, w);
                    if (w.output === target.output)
                        updated.is_active = w.id === change.id;
                    if (change.focused)
                        updated.is_focused = w.id === change.id;
                    return updated;
                });
            }
        } catch (error) {
            console.warn("Cannot parse niri event:", error);
        }
    }

    function readCpu(contents) {
        const fields = contents.split("\n")[0].trim().split(/\s+/);
        if (fields[0] !== "cpu") return;
        const n = fields.slice(1).map(Number);
        const total = n.reduce((sum, value) => sum + value, 0);
        const idle = n[3] + (n[4] || 0);
        if (prevTotal >= 0 && total > prevTotal)
            cpuPercent = Math.round(100 * (1 - (idle - prevIdle) / (total - prevTotal)));
        prevTotal = total;
        prevIdle = idle;
    }

    function readRam(contents) {
        const total = contents.match(/^MemTotal:\s+(\d+)/m);
        const available = contents.match(/^MemAvailable:\s+(\d+)/m);
        if (total && available)
            usedRam = ((Number(total[1]) - Number(available[1])) / 1048576).toFixed(2);
    }

    // Subscribe once for all three monitor bars. The stream sends initial
    // workspace state immediately, then changes as they occur (no polling).
    Process {
        id: niriEvents
        command: ["niri", "msg", "--json", "event-stream"]
        running: true
        stdout: SplitParser {
            onRead: data => root.handleNiriEvent(data)
        }
        onRunningChanged: {
            if (!running) reconnectNiri.start()
        }
    }

    Timer {
        id: reconnectNiri
        interval: 1500
        repeat: false
        onTriggered: niriEvents.running = true
    }

    FileView {
        id: walFile
        path: Quickshell.env("HOME") + "/.cache/wal/colors.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try { root.wal = JSON.parse(text()); }
            catch (e) { console.warn("Cannot read pywal colors:", e); }
        }
    }

    FileView {
        id: cpuFile
        path: "/proc/stat"
        onLoaded: root.readCpu(text())
    }

    FileView {
        id: ramFile
        path: "/proc/meminfo"
        onLoaded: root.readRam(text())
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            cpuFile.reload();
            ramFile.reload();
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // One independent layer-shell bar on every connected monitor.
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar
            required property var modelData
            screen: modelData

            // A stable model per output, so QML delegates survive activation
            // changes and their Behavior animations can actually run.
            ListModel { id: workspaceModel }

            function updateWorkspaceModel() {
                const current = bar.screen
                    ? root.workspaces
                        .filter(w => w.output === bar.screen.name)
                        .sort((a, b) => a.idx - b.idx)
                    : [];

                const sameWorkspaces = workspaceModel.count === current.length
                    && current.every((w, i) =>
                        workspaceModel.get(i).workspaceId === w.id);

                if (!sameWorkspaces) {
                    // Only rebuild when workspaces are actually added,
                    // removed, or reordered; NOT when focus changes.
                    workspaceModel.clear();
                    for (const w of current) {
                        workspaceModel.append({
                            workspaceId: w.id,
                            workspaceIndex: w.idx,
                            workspaceName: w.name || String(w.idx),
                            active: !!w.is_active
                        });
                    }
                } else {
                    for (let i = 0; i < current.length; ++i) {
                        workspaceModel.setProperty(i, "active", !!current[i].is_active);
                        workspaceModel.setProperty(i, "workspaceIndex", current[i].idx);
                        workspaceModel.setProperty(i, "workspaceName",
                                                   current[i].name || String(current[i].idx));
                    }
                }
            }

            Connections {
                target: root
                function onWorkspacesChanged() { bar.updateWorkspaceModel(); }
            }
            Component.onCompleted: updateWorkspaceModel()

            anchors { top: true; left: true; right: true }
            implicitHeight: 36

            // Normal top panel; reserves screen space in Niri.
            margins.top: 0
            exclusiveZone: 36
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(root.bg.r, root.bg.g, root.bg.b, 0.65)

                // Left: only the Niri workspaces belonging to this monitor.
                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 7

                    Repeater {
                        model: workspaceModel

                        delegate: Item {
                            id: wsButton
                            required property bool active
                            required property string workspaceName
                            required property int workspaceIndex
                            width: Math.max(30, wsText.implicitWidth + 16)
                            height: 36

                            Text {
                                id: wsText
                                anchors.centerIn: parent
                                text: wsButton.workspaceName
                                font.pixelSize: 15
                                font.bold: true
                                color: wsButton.active ? root.purple : root.fg
                            }
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: wsButton.active ? parent.width : 0
                                height: 2
                                color: root.purple

                                Behavior on width {
                                    NumberAnimation {
                                        duration: 250
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Quickshell.execDetached([
                                        "sh", "-c",
                                        'niri msg action focus-monitor "$1" && niri msg action focus-workspace "$2"',
                                        "sh", bar.screen.name, String(wsButton.workspaceIndex)
                                    ]);
                                }
                            }
                        }
                    }

                    Text {
                        text: "quickshell"
                        anchors.verticalCenter: parent.verticalCenter
                        leftPadding: 12
                        font.pixelSize: 14
                        font.bold: true
                        color: root.fg
                    }
                }

                // Center: the time and clickable date.
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 16

                    Rectangle {
                        width: timeText.implicitWidth + 28
                        height: 29
                        radius: 6
                        color: root.purple
                        Text {
                            id: timeText
                            anchors.centerIn: parent
                            text: Qt.formatDateTime(clock.date, "hh:mm")
                            color: root.bg
                            font.bold: true
                            font.pixelSize: 15
                        }
                    }
                    Rectangle {
                        width: dateText.implicitWidth + 28
                        height: 29
                        radius: 6
                        color: root.purple
                        Text {
                            id: dateText
                            anchors.centerIn: parent
                            text: Qt.formatDateTime(clock.date, "dd.MM.yy")
                            color: root.bg
                            font.bold: true
                            font.pixelSize: 15
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: calendarPopup.toggle()
                        }
                    }
                }

                // Right: shared CPU/RAM readings (computed only once).
                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 14

                    Rectangle {
                        width: ramText.implicitWidth + 24
                        height: 29
                        radius: 6
                        color: root.blue
                        Text {
                            id: ramText
                            anchors.centerIn: parent
                            text: "🧠 " + root.usedRam + "GB"
                            color: root.fg
                            font.bold: true
                            font.pixelSize: 15
                        }
                    }
                    Rectangle {
                        width: cpuText.implicitWidth + 24
                        height: 29
                        radius: 6
                        color: root.blue
                        Text {
                            id: cpuText
                            anchors.centerIn: parent
                            text: "⟳  " + root.cpuPercent + "%"
                            color: root.fg
                            font.bold: true
                            font.pixelSize: 15
                        }
                    }
                }
            }

            // A separate popup on each monitor, centered under that bar's date.
            CalendarPopup {
                id: calendarPopup
                anchor.window: bar
                anchor.rect.x: Math.round((bar.width - implicitWidth) / 2)
                anchor.rect.y: bar.height + 6
                backgroundColor: root.bg
                foregroundColor: root.fg
                accentColor: root.purple
                secondaryColor: root.blue
                currentDateTime: clock.date
            }
        }
    }
}
