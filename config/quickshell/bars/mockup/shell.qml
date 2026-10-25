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

    // Match the approved HTML palette exactly.
    property color bg: "#122957"
    property color fg: "#c6cff5"
    property color accent: "#8e81d9"
    property color secondary: "#3f5ac8"
    property color dark: "#0a1633"

    FontLoader { id: inter; source: "components/fonts/Inter.ttf" }
    readonly property string uiFont: inter.status === FontLoader.Ready ? inter.name : "Inter"

    property var workspaces: []
    property bool notifOpen: false
    // A single popup is shared across monitors so an outside click dismisses
    // the complete popup state rather than leaving another panel open.
    property string openPanel: ""
    property var popupScreen: null
    property bool dnd: false
    readonly property var notifications: notificationServer.trackedNotifications.values
    readonly property int notificationCount: notifications.length

    // The selected native drawer uses Quickshell's desktop-notifications server.
    // Only one process can own org.freedesktop.Notifications; SwayNC must not
    // be running as the competing notification daemon for this config.
    NotificationServer {
        id: notificationServer
        actionsSupported: true
        keepOnReload: true
        onNotification: notification => { notification.tracked = !root.dnd; }
    }
    function clearNotifications() {
        while (notificationServer.trackedNotifications.values.length > 0)
            notificationServer.trackedNotifications.values[0].dismiss();
    }
    function toggleDnd() { root.dnd = !root.dnd; }
    function closePopup() {
        root.openPanel = "";
        root.popupScreen = null;
    }
    function dismissPopup(name, screen) {
        // Ignore a late native-dismiss event if the click already switched to
        // another chip (or opened a popup on a different monitor).
        if (root.openPanel === name && root.popupScreen === screen)
            root.closePopup();
    }

    readonly property var mediaPlayers: Mpris.players.values
    // Keep an explicit source selection independent of playback state. Store
    // both the player reference and identity so it survives list reorder/reload.
    property var selectedMediaPlayer: null
    property string selectedMediaPlayerId: ""
    readonly property var mediaPlayer: {
        const players = root.mediaPlayers;
        if (root.selectedMediaPlayer && players.indexOf(root.selectedMediaPlayer) >= 0)
            return root.selectedMediaPlayer;
        if (root.selectedMediaPlayerId) {
            for (let i = 0; i < players.length; i++)
                if (players[i].identity === root.selectedMediaPlayerId) return players[i];
        }
        for (let i = 0; i < players.length; i++)
            if (players[i].isPlaying) return players[i];
        return players.length > 0 ? players[0] : null;
    }
    function cycleMediaPlayer() {
        const players = root.mediaPlayers;
        if (players.length < 2) return;
        const current = root.mediaPlayer;
        const index = players.indexOf(current);
        const next = players[(index + 1 + players.length) % players.length];
        root.selectedMediaPlayer = next;
        root.selectedMediaPlayerId = next.identity || "";
    }
    property var cavaLevels: new Array(20).fill(0)
    Process {
        id: cavaProcess
        command: ["cava", "-p", Quickshell.shellDir + "/components/media-cava.conf"]
        running: !!root.mediaPlayer && root.mediaPlayer.isPlaying
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(";");
                if (parts.length < 20) return;
                root.cavaLevels = parts.slice(0, 20).map(value => {
                    const parsed = Number(value);
                    // CAVA's linear 0-1000 amplitude is too small to see at low volume;
                    // a square-root gain keeps quiet audio responsive without fake motion.
                    return Number.isFinite(parsed) ? Math.max(0, Math.min(1, Math.sqrt(parsed / 1000) * 1.8)) : 0;
                });
            }
        }
        onRunningChanged: if (!running) root.cavaLevels = new Array(20).fill(0)
    }

    SysData {
        id: sysData
        bg: root.bg; fg: root.fg; accent: root.accent; secondary: root.secondary; dark: root.dark
    }

    SystemClock { id: clock; precision: SystemClock.Seconds }

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

            function toggle(name) {
                root.notifOpen = false;
                if (root.openPanel === name && root.popupScreen === bar.screen) {
                    root.closePopup();
                    return;
                }
                if (name === "wifi" || name === "bt" || name === "vol") sysData.refreshDevices();
                root.popupScreen = bar.screen;
                root.openPanel = name;
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
                color: Qt.rgba(root.bg.r, root.bg.g, root.bg.b, 0.45)
                border.width: 1
                border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.25)
            }
            BackgroundEffect.blurRegion: Region { item: frame }

            // ---- LEFT: workspaces + window title ----
                Row {
                    id: leftModules
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: implicitWidth
                    height: 30
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
                        // Four fixed 24px buttons, p-1, and the 1px border.
                        width: 4 * btnW + 10

                        // glider: sits behind the buttons and slides to the active one
                        Rectangle {
                            id: glider
                            x: 4 + wsBox.activeIdx * wsBox.btnW
                            y: (wsBox.height - height) / 2
                            width: wsBox.btnW; height: 16; radius: 6
                            color: root.accent
                            Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                        }

                        Row {
                            x: 4
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 0
                            Repeater {
                                model: [
                                    { idx: 1, icon: "circle-dot" },
                                    { idx: 2, icon: "terminal" },
                                    { idx: 3, icon: "globe" },
                                    { idx: 4, icon: "folder" }
                                ]
                                Item {
                                    required property var modelData
                                    width: wsBox.btnW; height: 30
                                    readonly property bool active: bar.wsList.some(w => w.idx === modelData.idx && w.is_active)
                                    Icon { anchors.centerIn: parent; name: modelData.icon; tone: parent.active ? "white" : "muted"; size: 14 }
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
                        id: titleBox
                        readonly property int maxTitleWidth: bar.screen.width >= 1024 ? 250 : 150
                        height: 22
                        width: Math.min(titleRow.implicitWidth + 18, maxTitleWidth)
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 6
                        color: Qt.rgba(root.dark.r, root.dark.g, root.dark.b, 0.2)
                        border.width: 1
                        border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.125)
                        Row {
                            id: titleRow
                            anchors.left: parent.left; anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8
                            Icon { name: "code-2"; tone: "secondary"; size: 14; anchors.verticalCenter: parent.verticalCenter }
                            Text {
                                text: sysData.windowTitle || "—"
                                color: root.fg
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                font.family: root.uiFont
                                elide: Text.ElideRight
                                width: Math.min(implicitWidth, titleBox.maxTitleWidth - 40)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }

                // ---- CENTER: media chip (opens media popup) ----
                MediaChip {
                    id: mediaChip
                    anchors.centerIn: parent
                    // Center in the flexible space between the side modules,
                    // matching the reference's flex-centered media island.
                    availableWidth: Math.max(0, Math.min(320,
                        frame.width - leftModules.width - rightModules.width - 52))
                    player: root.mediaPlayer
                    cavaLevels: root.cavaLevels
                    textColor: root.fg
                    iconColor: "#38bdf8"
                    fillColor: Qt.rgba(root.dark.r, root.dark.g, root.dark.b, 0.4)
                    hoverColor: Qt.rgba(root.secondary.r, root.secondary.g, root.secondary.b, 0.3)
                    borderColor: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.125)
                    highlighted: root.openPanel === "media" && root.popupScreen === bar.screen
                    onClicked: bar.toggle("media")
                }

                // ---- RIGHT: status chips ----
                Row {
                    id: rightModules
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: implicitWidth
                    height: 30
                    spacing: 10

                    Chip {
                        id: cpuChipAnchor
                        glyph: "cpu"; label: sysData.cpuPercent + "%"
                        horizontalPadding: 8; gap: 6; iconSize: 14
                        fillColor: Qt.rgba(root.secondary.r, root.secondary.g, root.secondary.b, 0.2)
                        borderColor: Qt.rgba(root.secondary.r, root.secondary.g, root.secondary.b, 0.3)
                        hoverColor: Qt.rgba(root.secondary.r, root.secondary.g, root.secondary.b, 0.4)
                        textColor: root.fg; iconColor: root.accent
                        highlighted: root.openPanel === "cpu" && root.popupScreen === bar.screen
                        onClicked: bar.toggle("cpu")
                    }
                    Chip {
                        id: ramChipAnchor
                        glyph: "memory-stick"; label: sysData.ramUsedGb.toFixed(1) + "GB"
                        horizontalPadding: 8; gap: 6; iconSize: 14
                        fillColor: Qt.rgba(root.secondary.r, root.secondary.g, root.secondary.b, 0.2)
                        borderColor: Qt.rgba(root.secondary.r, root.secondary.g, root.secondary.b, 0.3)
                        hoverColor: Qt.rgba(root.secondary.r, root.secondary.g, root.secondary.b, 0.4)
                        textColor: root.fg; iconColor: root.accent
                        highlighted: root.openPanel === "ram" && root.popupScreen === bar.screen
                        onClicked: bar.toggle("ram")
                    }
                    Chip {
                        id: diskChipAnchor
                        glyph: "hard-drive"
                        horizontalPadding: 8; gap: 6; iconSize: 14
                        label: {
                            const d = sysData.disks.find(x => x.mount === "/");
                            return d ? d.percent + "%" : "—";
                        }
                        fillColor: Qt.rgba(root.secondary.r, root.secondary.g, root.secondary.b, 0.2)
                        borderColor: Qt.rgba(root.secondary.r, root.secondary.g, root.secondary.b, 0.3)
                        hoverColor: Qt.rgba(root.secondary.r, root.secondary.g, root.secondary.b, 0.4)
                        textColor: root.fg; iconColor: root.accent
                        highlighted: root.openPanel === "disk" && root.popupScreen === bar.screen
                        onClicked: bar.toggle("disk")
                    }

                    // Wi-Fi icon with status dot
                    Chip {
                        id: wifiChipAnchor
                        glyph: "wifi"; label: ""; iconOnly: true
                        iconSize: 14
                        fillColor: "transparent"; borderColor: "transparent"
                        hoverColor: Qt.rgba(root.secondary.r, root.secondary.g, root.secondary.b, 0.3)
                        textColor: root.fg; iconColor: root.fg; iconTone: "fg"
                        highlighted: root.openPanel === "wifi" && root.popupScreen === bar.screen
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
                        glyph: "bluetooth"; label: ""; iconOnly: true
                        iconSize: 14
                        fillColor: "transparent"; borderColor: "transparent"
                        hoverColor: Qt.rgba(root.secondary.r, root.secondary.g, root.secondary.b, 0.3)
                        textColor: root.fg; iconColor: root.accent
                        highlighted: root.openPanel === "bt" && root.popupScreen === bar.screen
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
                        glyph: sysData.outMuted ? "volume-x" : "volume-2"
                        label: sysData.outMuted ? "Muted" : Math.round(sysData.outVolume * 100) + "%"
                        iconSize: 14; gap: 4
                        fillColor: "transparent"; borderColor: "transparent"
                        hoverColor: Qt.rgba(root.secondary.r, root.secondary.g, root.secondary.b, 0.3)
                        textColor: root.fg; iconColor: root.accent
                        highlighted: root.openPanel === "vol" && root.popupScreen === bar.screen
                        onClicked: bar.toggle("vol")
                    }
                    // Clock
                    Chip {
                        id: clockChipAnchor
                        glyph: "clock"
                        label: Qt.formatDateTime(clock.date, "MMM d") + " • " + Qt.formatDateTime(clock.date, "hh:mm")
                        iconSize: 12; horizontalPadding: 10; gap: 6; mono: false; bold: true
                        fillColor: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.2)
                        borderColor: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.4)
                        hoverColor: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.3)
                        textColor: "#ffffff"; iconColor: root.accent
                        highlighted: root.openPanel === "clock" && root.popupScreen === bar.screen
                        onClicked: bar.toggle("clock")
                    }
                    // Notifications bell
                    Chip {
                        glyph: "bell"; label: ""; iconOnly: true; iconSize: 14
                        fillColor: "transparent"; borderColor: "transparent"
                        hoverColor: Qt.rgba(root.secondary.r, root.secondary.g, root.secondary.b, 0.3)
                        textColor: root.fg; iconColor: root.accent
                        Rectangle {
                            visible: root.notificationCount > 0
                            anchors.right: parent.right; anchors.top: parent.top
                            anchors.rightMargin: 1; anchors.topMargin: 1
                            width: 14; height: 14; radius: 7; color: root.accent
                            Text { anchors.centerIn: parent; text: root.notificationCount; color: "white"; font.pixelSize: 9; font.bold: true; font.family: root.uiFont }
                        }
                        onClicked: {
                            root.closePopup();
                            root.notifOpen = !root.notifOpen;
                        }
                    }
                }

            // ---- Popups (all anchored to this bar) ----
            CpuPanel {
                anchor.window: bar; anchorItem: cpuChipAnchor; open: root.openPanel === "cpu" && root.popupScreen === bar.screen; sys: sysData
                onDismissed: root.dismissPopup("cpu", bar.screen)
            }
            RamPanel {
                anchor.window: bar; anchorItem: ramChipAnchor; open: root.openPanel === "ram" && root.popupScreen === bar.screen; sys: sysData
                onDismissed: root.dismissPopup("ram", bar.screen)
            }
            DiskPanel {
                anchor.window: bar; anchorItem: diskChipAnchor; open: root.openPanel === "disk" && root.popupScreen === bar.screen; sys: sysData
                onDismissed: root.dismissPopup("disk", bar.screen)
            }
            WifiPanel {
                anchor.window: bar; anchorItem: wifiChipAnchor; open: root.openPanel === "wifi" && root.popupScreen === bar.screen; sys: sysData
                onDismissed: root.dismissPopup("wifi", bar.screen)
            }
            BluetoothPanel {
                anchor.window: bar; anchorItem: btChipAnchor; open: root.openPanel === "bt" && root.popupScreen === bar.screen; sys: sysData
                onDismissed: root.dismissPopup("bt", bar.screen)
            }
            VolumePanel {
                anchor.window: bar; anchorItem: volChipAnchor; open: root.openPanel === "vol" && root.popupScreen === bar.screen; sys: sysData
                onDismissed: root.dismissPopup("vol", bar.screen)
            }
            ClockPanel {
                anchor.window: bar; anchorItem: clockChipAnchor; open: root.openPanel === "clock" && root.popupScreen === bar.screen
                now: clock.date
                bgColor: root.bg; fgColor: root.fg; accentColor: root.accent; secondaryColor: root.secondary
                onDismissed: root.dismissPopup("clock", bar.screen)
            }
            MediaPanel {
                anchor.window: bar; anchorItem: mediaChip; open: root.openPanel === "media" && root.popupScreen === bar.screen
                player: root.mediaPlayer
                players: root.mediaPlayers
                cavaLevels: root.cavaLevels
                bgColor: root.bg; fgColor: root.fg; accentColor: root.accent; secondaryColor: root.secondary
                onDismissed: root.dismissPopup("media", bar.screen)
                onSourceChangeRequested: root.cycleMediaPlayer()
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
