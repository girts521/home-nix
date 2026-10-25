import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import "." as MockupComponents

BarPanel {
    id: panel
    property color bgColor: MockupComponents.Palette.bg
    property color fgColor: MockupComponents.Palette.fg
    property color accentColor: MockupComponents.Palette.accent
    property color secondaryColor: MockupComponents.Palette.secondary
    property var player: null
    property var players: []
    property var cavaLevels: [0, 0, 0, 0, 0, 0]

    // The parent owns the selected MPRIS reference so the compact chip and
    // expanded controls always address the same player.
    signal sourceChangeRequested()

    bg: bgColor
    fg: fgColor
    accent: accentColor
    secondary: secondaryColor
    dark: MockupComponents.Palette.dark
    uiFont: "Inter"
    panelWidth: 320
    contentInset: 16
    contentSpacing: 12
    cornerRadius: 16

    readonly property real trackLength: player && player.length > 0 ? player.length : 0
    readonly property real trackPosition: player && player.position > 0 ? player.position : 0
    readonly property real progress: trackLength > 0 ? Math.max(0, Math.min(1, trackPosition / trackLength)) : 0
    readonly property int repeatMode: player ? player.loopState : MprisLoopState.None
    readonly property bool shuffleEnabled: player ? player.shuffle : false
    property string artworkUrl: ""
    onPlayerChanged: artworkUrl = player && player.trackArtUrl ? player.trackArtUrl : ""
    Connections {
        target: panel.player
        function onTrackArtUrlChanged() {
            panel.artworkUrl = panel.player && panel.player.trackArtUrl ? panel.player.trackArtUrl : "";
        }
    }
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            if (!panel.player || !panel.player.trackArtUrl) return;
            const url = panel.player.trackArtUrl;
            if (url !== panel.artworkUrl) panel.artworkUrl = url;
        }
    }

    function toggleShuffle() {
        if (player && player.shuffleSupported) player.shuffle = !player.shuffle;
    }
    function cycleRepeat() {
        if (!player || !player.loopSupported) return;
        if (player.loopState === MprisLoopState.None) player.loopState = MprisLoopState.Playlist;
        else if (player.loopState === MprisLoopState.Playlist) player.loopState = MprisLoopState.Track;
        else player.loopState = MprisLoopState.None;
    }

    function formatTime(seconds) {
        const value = Math.max(0, Math.floor(seconds));
        const minutes = Math.floor(value / 60);
        const secondsPart = value % 60;
        return minutes + ":" + (secondsPart < 10 ? "0" : "") + secondsPart;
    }
    function previous() { if (player && player.canGoPrevious) player.previous(); }
    function togglePlayback() { if (player && player.canTogglePlaying) player.togglePlaying(); }
    function next() { if (player && player.canGoNext) player.next(); }
    function seekTo(x) {
        if (!player || !player.canSeek || !player.positionSupported || trackLength <= 0) return;
        player.position = Math.max(0, Math.min(trackLength, trackLength * x / seekTrack.width));
    }

    Timer {
        interval: 1000
        repeat: true
        running: !!panel.player && panel.player.isPlaying && panel.player.positionSupported
        onTriggered: if (panel.player) panel.player.positionChanged()
    }

    Item {
        width: parent.width
        height: 26
        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            Icon { name: "music"; tone: "accent"; size: 16 }
            Text { text: "Media Player"; color: panel.fg; font.bold: true; font.pixelSize: 13; font.family: panel.uiFont }
        }
        Rectangle {
            id: playerBadge
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: badgeContent.implicitWidth + 14
            height: 20
            radius: 5
            visible: !!panel.player
            color: badgeMouse.containsMouse
                ? Qt.rgba(panel.secondary.r, panel.secondary.g, panel.secondary.b, 0.45)
                : Qt.rgba(panel.secondary.r, panel.secondary.g, panel.secondary.b, 0.25)
            border.width: 1
            border.color: Qt.rgba(panel.accent.r, panel.accent.g, panel.accent.b, 0.35)
            Row {
                id: badgeContent
                anchors.centerIn: parent
                spacing: 4
                Text {
                    id: playerName
                    text: panel.player ? panel.player.identity : ""
                    color: MockupComponents.Palette.cyan
                    font.pixelSize: 9
                    font.bold: true
                    font.family: panel.uiFont
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: panel.players.length > 1 ? "↻" : ""
                    color: panel.fg
                    opacity: 0.75
                    font.pixelSize: 10
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            MouseArea {
                id: badgeMouse
                anchors.fill: parent
                hoverEnabled: true
                enabled: panel.players.length > 1
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: panel.sourceChangeRequested()
            }
        }
    }

    Row {
        width: parent.width
        spacing: 16
        Item {
            width: 64
            height: 64
            Rectangle {
                id: albumArtFrame
                anchors.fill: parent
                radius: 12
                clip: true
                gradient: Gradient {
                    GradientStop { position: 0; color: panel.secondary }
                    GradientStop { position: 1; color: panel.accent }
                }
                Item {
                    id: artworkDisk
                    anchors.fill: parent
                    RotationAnimation on rotation {
                        running: !!panel.player && panel.player.isPlaying
                        from: 0
                        to: 360
                        duration: 8000
                        loops: Animation.Infinite
                    }
                    Image {
                        id: albumArt
                        anchors.fill: parent
                        source: panel.artworkUrl
                        visible: panel.artworkUrl !== "" && status === Image.Ready
                        asynchronous: true
                        cache: true
                        fillMode: Image.PreserveAspectCrop
                    }
                    Rectangle {
                        anchors.centerIn: parent
                        width: 16
                        height: 16
                        radius: 8
                        color: panel.bg
                        visible: !albumArt.visible
                    }
                }
            }
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 80
            Text {
                text: panel.player ? (panel.player.trackTitle || "Unknown title") : "No media playing"
                color: panel.fg
                font.bold: true
                font.pixelSize: 14
                font.family: panel.uiFont
                elide: Text.ElideRight
                width: parent.width
            }
            Text {
                text: panel.player ? (panel.player.trackArtist || panel.player.trackAlbum || "Unknown artist") : "Start an MPRIS-compatible player"
                color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.6)
                font.pixelSize: 12
                font.family: panel.uiFont
                elide: Text.ElideRight
                width: parent.width
            }
        }
    }

    Rectangle {
        width: parent.width
        height: 40
        radius: 8
        color: Qt.rgba(panel.dark.r, panel.dark.g, panel.dark.b, 0.5)
        border.width: 1
        border.color: Qt.rgba(panel.accent.r, panel.accent.g, panel.accent.b, 0.3)
        Row {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 2
            Repeater {
                model: 20
                Rectangle {
                    required property int index
                    width: (parent.width - 38) / 20
                    height: Math.min(24, 2 + ((panel.cavaLevels.length ? panel.cavaLevels[Math.floor(index * panel.cavaLevels.length / 20)] : 0) || 0) * 22)
                    anchors.bottom: parent.bottom
                    radius: 2
                    color: panel.accent
                    Behavior on height { NumberAnimation { duration: 65; easing.type: Easing.OutCubic } }
                }
            }
        }
    }

    Column {
        width: parent.width
        spacing: 4
        Rectangle {
            id: seekTrack
            width: parent.width
            height: 4
            radius: 2
            color: panel.dark
            Rectangle { width: parent.width * panel.progress; height: parent.height; radius: 2; color: panel.accent }
            MouseArea {
                anchors.fill: parent
                anchors.topMargin: -8
                anchors.bottomMargin: -8
                enabled: !!panel.player && panel.player.canSeek && panel.player.positionSupported && panel.trackLength > 0
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onPressed: mouse => panel.seekTo(mouse.x)
                onPositionChanged: mouse => { if (pressed) panel.seekTo(mouse.x); }
            }
        }
        Row {
            width: parent.width
            Text {
                width: parent.width / 2
                text: panel.player && panel.player.positionSupported ? panel.formatTime(panel.trackPosition) : "Live"
                color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.5)
                font.pixelSize: 10
                font.family: "monospace"
            }
            Text {
                width: parent.width / 2
                horizontalAlignment: Text.AlignRight
                text: panel.player && panel.player.lengthSupported ? panel.formatTime(panel.trackLength) : "Live"
                color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.5)
                font.pixelSize: 10
                font.family: "monospace"
            }
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 16
        Repeater {
            model: [
                { glyph: "shuffle", action: "shuffle" },
                { glyph: "skip-back", action: "previous" },
                { glyph: panel.player && panel.player.isPlaying ? "pause" : "play", action: "toggle" },
                { glyph: "skip-forward", action: "next" },
                { glyph: "repeat", action: "repeat" }
            ]
            Item {
                required property var modelData
                readonly property bool mainControl: modelData.action === "toggle"
                readonly property bool allowed: !!panel.player && (
                    modelData.action === "previous" ? panel.player.canGoPrevious :
                    modelData.action === "next" ? panel.player.canGoNext :
                    modelData.action === "shuffle" ? panel.player.shuffleSupported :
                    modelData.action === "repeat" ? panel.player.loopSupported : panel.player.canTogglePlaying)
                readonly property bool selected: modelData.action === "shuffle" ? panel.shuffleEnabled
                    : (modelData.action === "repeat" ? panel.repeatMode !== MprisLoopState.None : false)
                width: mainControl ? 40 : 24
                height: mainControl ? 40 : 24
                Rectangle { anchors.fill: parent; radius: width / 2; color: mainControl ? panel.accent : (selected ? Qt.rgba(panel.accent.r, panel.accent.g, panel.accent.b, 0.2) : "transparent") }
                Icon {
                    anchors.centerIn: parent
                    name: modelData.glyph
                    tone: mainControl ? "white" : (selected ? "accent" : "fg")
                    size: mainControl ? 20 : 16
                    opacity: allowed ? 1 : 0.45
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: allowed
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (modelData.action === "previous") panel.previous();
                        else if (modelData.action === "next") panel.next();
                        else if (modelData.action === "toggle") panel.togglePlayback();
                        else if (modelData.action === "shuffle") panel.toggleShuffle();
                        else if (modelData.action === "repeat") panel.cycleRepeat();
                    }
                }
            }
        }
    }
}
