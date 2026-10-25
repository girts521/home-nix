import QtQuick
import "." as MockupComponents

Rectangle {
    id: chip
    property var player: null
    property var cavaLevels: []
    property color textColor: MockupComponents.Palette.fg
    property color iconColor: MockupComponents.Palette.cyan
    property color fillColor: MockupComponents.Palette.dark
    property color hoverColor: MockupComponents.Palette.secondary
    property color borderColor: MockupComponents.Palette.accent
    property bool highlighted: false
    property real availableWidth: 320
    readonly property string artworkUrl: player && player.trackArtUrl ? player.trackArtUrl : ""

    signal clicked()

    height: 30
    width: Math.min(320, Math.max(0, availableWidth))
    radius: 15
    color: ma.containsMouse || highlighted ? hoverColor : fillColor
    border.width: 1
    border.color: borderColor
    Behavior on color { ColorAnimation { duration: 150 } }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: chip.clicked()
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        Item {
            id: artworkMark
            width: 14
            height: 14
            anchors.verticalCenter: parent.verticalCenter
            Icon {
                anchors.fill: parent
                name: "globe"
                tone: "sky"
                size: 14
                visible: !cover.visible
            }
            Image {
                id: cover
                anchors.fill: parent
                source: chip.artworkUrl
                visible: chip.artworkUrl !== "" && status === Image.Ready
                asynchronous: true
                cache: true
                fillMode: Image.PreserveAspectCrop
            }
        }

        Item {
            id: trackSection
            width: Math.max(0, parent.width - artworkMark.width - bars.implicitWidth - controls.width - 36)
            height: parent.height
            Row {
                anchors.centerIn: parent
                width: Math.min(implicitWidth, trackSection.width)
                spacing: 3
                Text {
                    id: trackTitle
                    text: chip.player
                        ? (chip.player.trackTitle || chip.player.identity || "Unknown track")
                        : "No media playing"
                    color: chip.textColor
                    font.pixelSize: 12
                    font.bold: true
                    font.family: "Inter"
                    elide: Text.ElideRight
                    width: Math.min(implicitWidth, chip.player && chip.player.trackArtist
                        ? Math.max(0, trackSection.width - 3) * 0.65 : trackSection.width)
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: chip.player && chip.player.trackArtist ? "— " + chip.player.trackArtist : ""
                    color: Qt.rgba(chip.textColor.r, chip.textColor.g, chip.textColor.b, 0.6)
                    font.pixelSize: 12
                    font.family: "Inter"
                    elide: Text.ElideRight
                    width: Math.min(implicitWidth, Math.max(0, trackSection.width - trackTitle.width - 3))
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        Row {
            id: bars
            anchors.verticalCenter: parent.verticalCenter
            height: 12
            spacing: 2
            Repeater {
                model: 6
                Rectangle {
                    required property int index
                    height: Math.min(12, 1 + ((chip.cavaLevels.length ? chip.cavaLevels[Math.floor(index * chip.cavaLevels.length / 6)] : 0) || 0) * 11)
                    width: 3
                    radius: 2
                    color: MockupComponents.Palette.accent
                    anchors.bottom: parent.bottom
                    Behavior on height { NumberAnimation { duration: 65; easing.type: Easing.OutCubic } }
                }
            }
        }

        Row {
            id: controls
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0
            Rectangle {
                width: 1
                height: 16
                color: Qt.rgba(chip.textColor.r, chip.textColor.g, chip.textColor.b, 0.2)
                anchors.verticalCenter: parent.verticalCenter
            }
            Item { width: 8; height: 1 }
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                Icon {
                    name: "skip-back"
                    tone: "fg"
                    size: 14
                    opacity: chip.player && chip.player.canGoPrevious ? 1 : 0.35
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        enabled: !!chip.player && chip.player.canGoPrevious
                        cursorShape: Qt.PointingHandCursor
                        onClicked: chip.player.previous()
                    }
                }
                Icon {
                    name: chip.player && chip.player.isPlaying ? "pause" : "play"
                    tone: "fg"
                    size: 14
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        enabled: !!chip.player && chip.player.canTogglePlaying
                        cursorShape: Qt.PointingHandCursor
                        onClicked: chip.player.togglePlaying()
                    }
                }
                Icon {
                    name: "skip-forward"
                    tone: "fg"
                    size: 14
                    opacity: chip.player && chip.player.canGoNext ? 1 : 0.35
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        enabled: !!chip.player && chip.player.canGoNext
                        cursorShape: Qt.PointingHandCursor
                        onClicked: chip.player.next()
                    }
                }
            }
        }
    }
}
