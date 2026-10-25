import Quickshell
import Quickshell.Services.Mpris
import QtQuick

BarPanel {
    id: panel
    property color bgColor: "#122957"
    property color fgColor: "#c6cff5"
    property color accentColor: "#8e81d9"
    property color secondaryColor: "#3f5ac8"
    property var player: null

    bg: bgColor; fg: fgColor; accent: accentColor; secondary: secondaryColor
    panelWidth: 320

    readonly property real trackLength: player && player.length > 0 ? player.length : 0
    readonly property real trackPosition: player && player.position > 0 ? player.position : 0
    readonly property real progress: trackLength > 0 ? Math.max(0, Math.min(1, trackPosition / trackLength)) : 0

    function formatTime(seconds) {
        const value = Math.max(0, Math.floor(seconds));
        const minutes = Math.floor(value / 60);
        const secondsPart = value % 60;
        return minutes + ":" + (secondsPart < 10 ? "0" : "") + secondsPart;
    }

    function previous() {
        if (player && player.canGoPrevious) player.previous();
    }
    function togglePlayback() {
        if (player && player.canTogglePlaying) player.togglePlaying();
    }
    function next() {
        if (player && player.canGoNext) player.next();
    }
    function seekTo(x) {
        if (!player || !player.canSeek || !player.positionSupported || trackLength <= 0) return;
        player.position = Math.max(0, Math.min(trackLength, trackLength * x / seekTrack.width));
    }

    Timer {
        interval: 1000
        repeat: true
        running: !!panel.player && panel.player.isPlaying && panel.player.positionSupported
        onTriggered: panel.player.positionChanged()
    }

    Item {
        width: parent.width
        height: 26
        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            Text { text: "♫"; color: panel.accent; font.pixelSize: 16 }
            Text { text: "Media Player"; color: panel.fg; font.bold: true; font.pixelSize: 13 }
        }
        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: playerText.implicitWidth + 12; height: 18; radius: 4
            visible: !!panel.player
            color: Qt.rgba(panel.secondary.r, panel.secondary.g, panel.secondary.b, 0.25)
            Text {
                id: playerText
                anchors.centerIn: parent
                text: panel.player ? panel.player.identity : ""
                color: "#7dd3fc"; font.pixelSize: 9; font.bold: true
            }
        }
    }

    Row {
        width: parent.width
        spacing: 12
        Rectangle {
            width: 64; height: 64; radius: 12; clip: true
            gradient: Gradient {
                GradientStop { position: 0; color: panel.secondary }
                GradientStop { position: 1; color: panel.accent }
            }
            Image {
                id: artwork
                anchors.fill: parent
                source: panel.player ? panel.player.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready
            }
            Rectangle { anchors.centerIn: parent; width: 16; height: 16; radius: 8; color: panel.bg; visible: !artwork.visible }
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 76
            Text {
                text: panel.player ? (panel.player.trackTitle || "Unknown title") : "No media playing"
                color: panel.fg; font.bold: true; font.pixelSize: 13
                elide: Text.ElideRight; width: parent.width
            }
            Text {
                text: panel.player ? (panel.player.trackArtist || panel.player.trackAlbum || "Unknown artist") : "Start an MPRIS-compatible player"
                color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.6); font.pixelSize: 11
                elide: Text.ElideRight; width: parent.width
            }
        }
    }

    Column {
        width: parent.width
        spacing: 4
        Rectangle {
            id: seekTrack
            width: parent.width; height: 4; radius: 2
            color: Qt.rgba(0.04, 0.08, 0.2, 1)
            Rectangle { width: parent.width * panel.progress; height: parent.height; radius: 2; color: panel.accent }
            MouseArea {
                anchors.fill: parent
                anchors.topMargin: -8; anchors.bottomMargin: -8
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
                color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.5); font.pixelSize: 10; font.family: "monospace"
            }
            Text {
                width: parent.width / 2
                horizontalAlignment: Text.AlignRight
                text: panel.player && panel.player.lengthSupported ? panel.formatTime(panel.trackLength) : "Live"
                color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.5); font.pixelSize: 10; font.family: "monospace"
            }
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 22
        Repeater {
            model: [
                { glyph: "⏮", action: "previous" },
                { glyph: panel.player && panel.player.isPlaying ? "⏸" : "▶", action: "toggle" },
                { glyph: "⏭", action: "next" }
            ]
            Rectangle {
                required property var modelData
                readonly property bool mainControl: modelData.action === "toggle"
                readonly property bool allowed: !!panel.player && (modelData.action === "previous" ? panel.player.canGoPrevious : modelData.action === "next" ? panel.player.canGoNext : panel.player.canTogglePlaying)
                width: mainControl ? 40 : 26
                height: width
                radius: width / 2
                color: mainControl ? panel.accent : "transparent"
                opacity: allowed ? 1 : 0.35
                Text {
                    anchors.centerIn: parent
                    text: modelData.glyph
                    color: mainControl ? "#ffffff" : panel.fg
                    font.pixelSize: mainControl ? 18 : 14
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: parent.allowed
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (modelData.action === "previous") panel.previous();
                        else if (modelData.action === "next") panel.next();
                        else panel.togglePlayback();
                    }
                }
            }
        }
    }
}
