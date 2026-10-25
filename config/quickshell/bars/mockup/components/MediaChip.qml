import QtQuick

Rectangle {
    id: chip
    property var player: null
    property color textColor: "#c6cff5"
    property color iconColor: "#38bdf8"
    property color fillColor: "#0a1633"
    property color hoverColor: "#3f5ac8"
    property color borderColor: "#8e81d9"
    property bool highlighted: false

    signal clicked()

    height: 30
    width: Math.min(320, chip.availableWidth)
    property real availableWidth: 320
    radius: 15
    color: ma.containsMouse || highlighted ? Qt.rgba(hoverColor.r, hoverColor.g, hoverColor.b, 0.3) : Qt.rgba(fillColor.r, fillColor.g, fillColor.b, 0.4)
    border.width: 1
    border.color: Qt.rgba(borderColor.r, borderColor.g, borderColor.b, 0.15)
    Behavior on color { ColorAnimation { duration: 150 } }

    Row {
        anchors.fill: parent
        anchors.leftMargin: 12; anchors.rightMargin: 8
        spacing: 8
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "🌐"; color: chip.iconColor; font.pixelSize: 13
        }
        Text {
            id: trackText
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, parent.width - 110)
            text: chip.player
                ? (chip.player.trackTitle || chip.player.identity || "Unknown track")
                    + (chip.player.trackArtist ? " — " + chip.player.trackArtist : "")
                : "No media playing"
            color: chip.textColor; font.pixelSize: 12; font.bold: true
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
        Item { width: Math.max(0, parent.width - trackText.width - 110) }
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5
            Text {
                text: "⏮"; color: chip.player && chip.player.canGoPrevious ? chip.textColor : Qt.rgba(chip.textColor.r, chip.textColor.g, chip.textColor.b, 0.35)
                font.pixelSize: 11
                MouseArea { anchors.fill: parent; anchors.margins: -5; enabled: !!chip.player && chip.player.canGoPrevious; cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor; onClicked: chip.player.previous() }
            }
            Text {
                text: chip.player && chip.player.isPlaying ? "⏸" : "▶"
                color: chip.player && chip.player.canTogglePlaying ? chip.textColor : Qt.rgba(chip.textColor.r, chip.textColor.g, chip.textColor.b, 0.35)
                font.pixelSize: 11
                MouseArea { anchors.fill: parent; anchors.margins: -5; enabled: !!chip.player && chip.player.canTogglePlaying; cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor; onClicked: chip.player.togglePlaying() }
            }
            Text {
                text: "⏭"; color: chip.player && chip.player.canGoNext ? chip.textColor : Qt.rgba(chip.textColor.r, chip.textColor.g, chip.textColor.b, 0.35)
                font.pixelSize: 11
                MouseArea { anchors.fill: parent; anchors.margins: -5; enabled: !!chip.player && chip.player.canGoNext; cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor; onClicked: chip.player.next() }
            }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        anchors.rightMargin: 100
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: chip.clicked()
    }
}
