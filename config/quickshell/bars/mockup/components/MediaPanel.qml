import Quickshell
import QtQuick

BarPanel {
    id: panel
    property color bgColor: "#122957"
    property color fgColor: "#c6cff5"
    property color accentColor: "#8e81d9"
    property color secondaryColor: "#3f5ac8"
    bg: bgColor; fg: fgColor; accent: accentColor; secondary: secondaryColor
    panelWidth: 320

    // Mock media state (mirrors the HTML mockup). Hook playerctl here later.
    property bool playing: true
    property real progress: 0.65

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
            width: fbText.implicitWidth + 12; height: 18; radius: 4
            color: Qt.rgba(panel.secondary.r, panel.secondary.g, panel.secondary.b, 0.25)
            Text { id: fbText; anchors.centerIn: parent; text: "Firefox Priority"; color: "#7dd3fc"; font.pixelSize: 9; font.bold: true }
        }
    }

    Row {
        width: parent.width
        spacing: 12
        Rectangle {
            width: 64; height: 64; radius: 12
            gradient: Gradient {
                GradientStop { position: 0; color: panel.secondary }
                GradientStop { position: 1; color: panel.accent }
            }
            Rectangle { anchors.centerIn: parent; width: 16; height: 16; radius: 8; color: panel.bg }
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 76
            Text { text: "Synthwave Radio"; color: panel.fg; font.bold: true; font.pixelSize: 13; elide: Text.ElideRight; width: parent.width }
            Text { text: "Lofi Girl"; color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.6); font.pixelSize: 11 }
        }
    }

    // Expanded visualiser
    Rectangle {
        width: parent.width; height: 40; radius: 8
        color: Qt.rgba(0.04, 0.08, 0.2, 0.5)
        Row {
            anchors.fill: parent; anchors.margins: 8
            spacing: 2
            Repeater {
                model: 20
                Rectangle {
                    required property int index
                    width: (parent.width - 19 * 2) / 20
                    height: 6 + Math.abs(Math.sin(index * 0.7)) * 20
                    anchors.bottom: parent.bottom
                    radius: 2
                    color: panel.accent
                }
            }
        }
    }

    Column {
        width: parent.width
        spacing: 4
        Rectangle {
            width: parent.width; height: 4; radius: 2; color: Qt.rgba(0.04, 0.08, 0.2, 1)
            Rectangle { width: parent.width * panel.progress; height: parent.height; radius: 2; color: panel.accent }
        }
        Row {
            width: parent.width
            Text { width: parent.width / 2; text: "2:14"; color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.5); font.pixelSize: 10; font.family: "monospace" }
            Text { width: parent.width / 2; horizontalAlignment: Text.AlignRight; text: "Live"; color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.5); font.pixelSize: 10; font.family: "monospace" }
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 22
        Repeater {
            model: [
                { g: "⤮", big: false, act: "shuffle" },
                { g: "⏮", big: false, act: "prev" },
                { g: panel.playing ? "⏸" : "▶", big: true, act: "play" },
                { g: "⏭", big: false, act: "next" },
                { g: "↻", big: false, act: "repeat" }
            ]
            Rectangle {
                required property var modelData
                width: modelData.big ? 40 : 26
                height: width
                radius: width / 2
                color: modelData.big ? panel.accent : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: modelData.g
                    color: modelData.big ? "#ffffff" : panel.fg
                    font.pixelSize: modelData.big ? 18 : 14
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (modelData.act === "play") panel.playing = !panel.playing
                }
            }
        }
    }
}
