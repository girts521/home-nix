import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Services.Notifications
import QtQuick
import "components"

// Mockup bar: a port of reference.html (../reference.html) to Quickshell.
// Layout, colors, popups and behaviour follow the HTML. Data comes from SysData.
Scope {
    id: root

    // Pywal palette with the same fallbacks as the HTML mockup.
    property var wal: ({})
    property color bg: wal.special && wal.special.background ? wal.special.background : "#122957"
    property color fg: wal.special && wal.special.foreground ? wal.special.foreground : "#c6cff5"
    property color accent: wal.colors && wal.colors.color5 ? wal.colors.color5 : "#8e81d9"
    property color secondary: wal.colors && wal.colors.color4 ? wal.colors.color4 : "#3f5ac8"
    property color dark: "#0a1633"

    property var workspaces: []
    property bool notifOpen: false
    property bool dnd: false
    property var notifications: []
    readonly property int notificationCount: notificationServer.trackedNotifications.values.length

    NotificationServer {
        id: notificationServer
        keepOnReload: true
        bodySupported: true
        actionsSupported: true
        imageSupported: true
        onNotification: notification => {
            notification.tracked = true;
            root.notifications = notificationServer.trackedNotifications.values.slice();
        }
        Component.onCompleted: root.notifications = trackedNotifications.values.slice()
    }
    Connections {
        target: notificationServer.trackedNotifications
        function onObjectInsertedPost() { root.notifications = notificationServer.trackedNotifications.values.slice(); }
        function onObjectRemovedPost() { root.notifications = notificationServer.trackedNotifications.values.slice(); }
    }
    function clearNotifications() {
        const pending = root.notifications.slice();
        for (let i = 0; i < pending.length; i++) pending[i].dismiss();
        root.notifications = notificationServer.trackedNotifications.values.slice();
    }
    Process {
        id: dndProc
        command: ["swaync-client", "--get-dnd"]
        stdout: StdioCollector { onStreamFinished: root.dnd = this.text.trim() === "true" }
    }
    function toggleDnd() {
        Quickshell.execDetached(["swaync-client", "--toggle-dnd"]);
        dndProc.running = true;
    }
    Timer {
        interval: 5000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: dndProc.running = true
    }

    readonly property var mediaPlayers: Mpris.players.values
    readonly property var mediaPlayer: {
        const players = root.mediaPlayers;
        for (let i = 0; i < players.length; i++)
            if (players[i].isPlaying) return players[i];
        return players.length > 0 ? players[0] : null;
    }

    SysData {
        id: sysData
        bg: root.bg; fg: root.fg; accent: root.accent; secondary: root.secondary; dark: root.dark
    }

    SystemClock { id: clock; precision: SystemClock.Seconds }

    FileView {
        path: Quickshell.env("HOME") + "/.cache/wal/colors.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try { root.wal = JSON.parse(text()); }
            catch (e) { console.warn("Cannot read pywal colors:", e); }
        }
    }

    // Niri workspaces (same event stream as the existing bar).
    Process {
        id: niriEvents
        command: ["niri", "msg", "--json", "event-stream"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                try {
                    const ev = JSON.parse(data);
                    if (ev.WorkspacesChanged) {
                        root.workspaces = ev.WorkspacesChanged.workspaces;
                    } else if (ev.WorkspaceActivated) {
                        const c = ev.WorkspaceActivated;
                        const t = root.workspaces.find(w => w.id === c.id);
                        if (!t) return;
                        root.workspaces = root.workspaces.map(w => {
                            const u = Object.assign({}, w);
                            if (w.output === t.output) u.is_active = w.id === c.id;
                            if (c.focused) u.is_focused = w.id === c.id;
                            return u;
                        });
                    }
                } catch (e) { console.warn("Cannot parse niri event:", e); }
            }
        }
        onRunningChanged: if (!running) reconnect.start()
    }
    Timer { id: reconnect; interval: 1500; onTriggered: niriEvents.running = true }

    // Niri's event stream sends an initial event snapshot after connecting.
    // This fallback guarantees useful workspaces even if the first lines are missed.
    Process {
        id: workspaceSnapshot
        command: ["niri", "msg", "--json", "workspaces"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.workspaces = JSON.parse(this.text); }
                catch (e) { console.warn("Cannot read niri workspaces:", e); }
            }
        }
    }
    Timer { interval: 5000; running: true; repeat: true; triggeredOnStart: true; onTriggered: workspaceSnapshot.running = true }

    // Keep wifi / bluetooth / audio lists fresh while the bar is alive.
    Timer { interval: 10000; running: true; repeat: true; onTriggered: sysData.refreshDevices() }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar
            required property var modelData
            screen: modelData

            // Which popup is open on this bar ("" = none).
            property string openPanel: ""
            function toggle(name) {
                if (openPanel === name) { openPanel = ""; return; }
                if (name === "wifi" || name === "bt" || name === "vol") sysData.refreshDevices();
                openPanel = name;
            }

            readonly property var wsList: root.workspaces
                .filter(w => w.output === bar.screen.name)
                .sort((a, b) => a.idx - b.idx)

            anchors { top: true; left: true; right: true }
            margins { top: 10; left: 6; right: 6 }
            implicitHeight: 50
            exclusiveZone: 60
            color: "transparent"

            Rectangle {
                id: frame
                anchors.fill: parent
                radius: 10
                color: Qt.rgba(root.bg.r, root.bg.g, root.bg.b, 0.65)
                border.width: 1
                border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.25)

                // ---- LEFT: workspaces + window title ----
                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    Rectangle {
                        id: wsBox
                        height: 30
                        radius: 8
                        color: Qt.rgba(root.dark.r, root.dark.g, root.dark.b, 0.5)
                        border.width: 1
                        border.color: Qt.rgba(root.secondary.r, root.secondary.g, root.secondary.b, 0.3)

                        readonly property int btnW: 24
                        readonly property int activeIdx: Math.max(0, bar.wsList.findIndex(w => !!w.is_active))
                        width: bar.wsList.length * btnW + 8

                        // glider: sits behind the buttons and slides to the active one
                        Rectangle {
                            id: glider
                            x: 4 + wsBox.activeIdx * wsBox.btnW
                            y: (wsBox.height - height) / 2
                            width: wsBox.btnW; height: 22; radius: 6
                            color: root.accent
                            Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                        }

                        Row {
                            x: 4
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 0
                            Repeater {
                                model: bar.wsList
                                Item {
                                    required property var modelData
                                    width: wsBox.btnW; height: 30
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.name || String(modelData.idx)
                                        color: modelData.is_active ? "#ffffff" : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.5)
                                        font.pixelSize: 12; font.bold: true
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Quickshell.execDetached([
                                            "sh", "-c",
                                            'niri msg action focus-monitor "$1" && niri msg action focus-workspace "$2"',
                                            "sh", bar.screen.name, String(modelData.idx)
                                        ])
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        height: 30
                        width: Math.min(titleRow.implicitWidth + 16, 250)
                        radius: 6
                        color: Qt.rgba(root.dark.r, root.dark.g, root.dark.b, 0.2)
                        border.width: 1
                        border.color: Qt.rgba(root.secondary.r, root.secondary.g, root.secondary.b, 0.5)
                        Row {
                            id: titleRow
                            anchors.left: parent.left; anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6
                            Text { text: "⌨"; color: root.secondary; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                            Text {
                                text: sysData.windowTitle || "—"
                                color: root.fg; font.pixelSize: 12
                                elide: Text.ElideRight
                                width: Math.min(implicitWidth, 220)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }

                // ---- CENTER: media chip (opens media popup) ----
                MediaChip {
                    id: mediaChip
                    anchors.centerIn: parent
                    availableWidth: Math.max(120, parent.width * 0.3)
                    player: root.mediaPlayer
                    textColor: root.fg
                    iconColor: "#38bdf8"
                    fillColor: root.dark
                    hoverColor: root.secondary
                    borderColor: root.fg
                    highlighted: bar.openPanel === "media"
                    onClicked: bar.toggle("media")
                }

                // ---- RIGHT: status chips ----
                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Chip {
                        id: cpuChipAnchor
                        glyph: "⟳"; label: sysData.cpuPercent + "%"
                        fillColor: Qt.rgba(root.secondary.r, root.secondary.g, root.secondary.b, 0.2)
                        borderColor: Qt.rgba(root.secondary.r, root.secondary.g, root.secondary.b, 0.3)
                        hoverColor: Qt.rgba(root.secondary.r, root.secondary.g, root.secondary.b, 0.4)
                        textColor: root.fg; iconColor: root.accent
                        highlighted: bar.openPanel === "cpu"
                        onClicked: bar.toggle("cpu")
                    }
                    Chip {
                        id: ramChipAnchor
                        glyph: "▤"; label: sysData.ramUsedGb.toFixed(1) + "GB"
                        fillColor: Qt.rgba(root.secondary.r, root.secondary.g, root.secondary.b, 0.2)
                        borderColor: Qt.rgba(root.secondary.r, root.secondary.g, root.secondary.b, 0.3)
                        hoverColor: Qt.rgba(root.secondary.r, root.secondary.g, root.secondary.b, 0.4)
                        textColor: root.fg; iconColor: root.accent
                        highlighted: bar.openPanel === "ram"
                        onClicked: bar.toggle("ram")
                    }
                    Chip {
                        id: diskChipAnchor
                        glyph: "⛁"
                        label: {
                            const d = sysData.disks.find(x => x.mount === "/");
                            return d ? d.percent + "%" : "—";
                        }
                        fillColor: Qt.rgba(root.secondary.r, root.secondary.g, root.secondary.b, 0.2)
                        borderColor: Qt.rgba(root.secondary.r, root.secondary.g, root.secondary.b, 0.3)
                        hoverColor: Qt.rgba(root.secondary.r, root.secondary.g, root.secondary.b, 0.4)
                        textColor: root.fg; iconColor: root.accent
                        highlighted: bar.openPanel === "disk"
                        onClicked: bar.toggle("disk")
                    }

                    // Wi-Fi icon with status dot
                    Chip {
                        id: wifiChipAnchor
                        glyph: "≋"; label: ""
                        width: 28
                        fillColor: "transparent"; borderColor: "transparent"
                        hoverColor: Qt.rgba(root.secondary.r, root.secondary.g, root.secondary.b, 0.3)
                        textColor: root.fg; iconColor: root.fg
                        highlighted: bar.openPanel === "wifi"
                        onClicked: bar.toggle("wifi")
                        Rectangle {
                            width: 6; height: 6; radius: 3; color: "#34d399"
                            anchors.right: parent.right; anchors.bottom: parent.bottom
                            anchors.margins: 3
                            visible: sysData.wifiOn
                        }
                    }
                    // Bluetooth icon with status dot
                    Chip {
                        id: btChipAnchor
                        glyph: "ᛒ"; label: ""
                        width: 28
                        fillColor: "transparent"; borderColor: "transparent"
                        hoverColor: Qt.rgba(root.secondary.r, root.secondary.g, root.secondary.b, 0.3)
                        textColor: root.fg; iconColor: root.accent
                        highlighted: bar.openPanel === "bt"
                        onClicked: bar.toggle("bt")
                        Rectangle {
                            width: 6; height: 6; radius: 3; color: "#38bdf8"
                            anchors.right: parent.right; anchors.bottom: parent.bottom
                            anchors.margins: 3
                            visible: sysData.btOn
                        }
                    }
                    // Volume
                    Chip {
                        id: volChipAnchor
                        glyph: "♪"
                        label: sysData.outMuted ? "Muted" : Math.round(sysData.outVolume * 100) + "%"
                        fillColor: "transparent"; borderColor: "transparent"
                        hoverColor: Qt.rgba(root.secondary.r, root.secondary.g, root.secondary.b, 0.3)
                        textColor: root.fg; iconColor: root.accent
                        highlighted: bar.openPanel === "vol"
                        onClicked: bar.toggle("vol")
                    }
                    // Clock
                    Chip {
                        id: clockChipAnchor
                        glyph: "◷"
                        label: Qt.formatDateTime(clock.date, "MMM d") + " • " + Qt.formatDateTime(clock.date, "hh:mm")
                        fillColor: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.2)
                        borderColor: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.4)
                        hoverColor: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.3)
                        textColor: "#ffffff"; iconColor: root.accent
                        highlighted: bar.openPanel === "clock"
                        onClicked: bar.toggle("clock")
                    }
                    // Notifications bell
                    Chip {
                        glyph: "🔔"; label: String(root.notificationCount)
                        fillColor: "transparent"; borderColor: "transparent"
                        hoverColor: Qt.rgba(root.secondary.r, root.secondary.g, root.secondary.b, 0.3)
                        textColor: root.fg; iconColor: root.accent
                        onClicked: root.notifOpen = !root.notifOpen
                    }
                }
            }

            // ---- Popups (all anchored to this bar) ----
            CpuPanel {
                anchor.window: bar; anchorItem: cpuChipAnchor; open: bar.openPanel === "cpu"; sys: sysData
                onDismissed: bar.openPanel = ""
            }
            RamPanel {
                anchor.window: bar; anchorItem: ramChipAnchor; open: bar.openPanel === "ram"; sys: sysData
                onDismissed: bar.openPanel = ""
            }
            DiskPanel {
                anchor.window: bar; anchorItem: diskChipAnchor; open: bar.openPanel === "disk"; sys: sysData
                onDismissed: bar.openPanel = ""
            }
            WifiPanel {
                anchor.window: bar; anchorItem: wifiChipAnchor; open: bar.openPanel === "wifi"; sys: sysData
                onDismissed: bar.openPanel = ""
            }
            BluetoothPanel {
                anchor.window: bar; anchorItem: btChipAnchor; open: bar.openPanel === "bt"; sys: sysData
                onDismissed: bar.openPanel = ""
            }
            VolumePanel {
                anchor.window: bar; anchorItem: volChipAnchor; open: bar.openPanel === "vol"; sys: sysData
                onDismissed: bar.openPanel = ""
            }
            ClockPanel {
                anchor.window: bar; anchorItem: clockChipAnchor; open: bar.openPanel === "clock"
                now: clock.date
                bgColor: root.bg; fgColor: root.fg; accentColor: root.accent; secondaryColor: root.secondary
                onDismissed: bar.openPanel = ""
            }
            MediaPanel {
                anchor.window: bar; anchorItem: mediaChip; open: bar.openPanel === "media"
                player: root.mediaPlayer
                bgColor: root.bg; fgColor: root.fg; accentColor: root.accent; secondaryColor: root.secondary
                onDismissed: bar.openPanel = ""
            }
        }
    }

    // Native notification center overlay on the primary screen.
    PanelWindow {
        id: notifWindow
        screen: Quickshell.screens[0]
        anchors { top: true; bottom: true; right: true }
        implicitWidth: 320
        color: "transparent"
        visible: root.notifOpen
        exclusionMode: ExclusionMode.Ignore

        NotifDrawer {
            id: notifDrawer
            width: notifWindow.implicitWidth
            height: notifWindow.height
            open: root.notifOpen
            notifications: root.notifications
            dnd: root.dnd
            bg: root.bg; fg: root.fg; accent: root.accent; secondary: root.secondary
            onClosed: root.notifOpen = false
            onClearRequested: root.clearNotifications()
            onDndToggled: root.toggleDnd()
        }
    }
}
