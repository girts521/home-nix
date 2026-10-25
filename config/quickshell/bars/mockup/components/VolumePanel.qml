import Quickshell
import QtQuick

BarPanel {
    id: panel
    required property var sys

    bg: sys.bg; fg: sys.fg; accent: sys.accent; secondary: sys.secondary
    panelWidth: 320

    property int tab: 0   // 0 = output, 1 = input
    readonly property var devices: tab === 0 ? sys.audioOutputs : sys.audioInputs
    readonly property real vol: tab === 0 ? sys.outVolume : sys.inVolume
    readonly property bool muted: tab === 0 ? sys.outMuted : sys.inMuted
    readonly property string targetId: {
        const d = devices.find(x => x.active);
        return d ? d.id : (tab === 0 ? "@DEFAULT_AUDIO_SINK@" : "@DEFAULT_AUDIO_SOURCE@");
    }

    Item {
        width: parent.width
        height: 28
        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            Text { text: "♪"; color: panel.accent; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter }
            Text { text: "Sound"; color: panel.fg; font.bold: true; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
        }
        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: muteText.implicitWidth + 14; height: 20; radius: 4
            color: muteMa.containsMouse ? Qt.rgba(panel.accent.r, panel.accent.g, panel.accent.b, 0.3) : "transparent"
            Text { id: muteText; anchors.centerIn: parent; text: panel.muted ? "Unmute" : "Mute"; color: panel.fg; font.pixelSize: 11 }
            MouseArea { id: muteMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["wpctl", "set-mute", panel.targetId, "toggle"]) }
        }
    }

    // Output / Input tabs
    Row {
        width: parent.width
        spacing: 0
        Repeater {
            model: ["Output", "Input"]
            Rectangle {
                required property var modelData
                required property int index
                width: parent.width / 2
                height: 26
                radius: 6
                color: panel.tab === index ? Qt.rgba(panel.accent.r, panel.accent.g, panel.accent.b, 0.35) : "transparent"
                Text { anchors.centerIn: parent; text: modelData; color: panel.fg; font.pixelSize: 11; font.bold: panel.tab === index }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: panel.tab = index }
            }
        }
    }

    // Device selector
    Column {
        width: parent.width
        spacing: 4
        Text {
            text: (panel.tab === 0 ? "OUTPUT DEVICE" : "INPUT DEVICE")
            color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.5); font.pixelSize: 10; font.bold: true
        }
        Repeater {
            model: panel.devices
            Rectangle {
                required property var modelData
                width: parent.width
                height: 28
                radius: 6
                color: modelData.active
                    ? Qt.rgba(panel.accent.r, panel.accent.g, panel.accent.b, 0.25)
                    : (devMa.containsMouse ? Qt.rgba(panel.accent.r, panel.accent.g, panel.accent.b, 0.12) : "transparent")
                Text {
                    anchors.left: parent.left; anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.name
                    color: modelData.active ? panel.fg : Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.7)
                    font.pixelSize: 12; font.bold: modelData.active
                    elide: Text.ElideRight
                    width: parent.width - 30
                }
                Text {
                    anchors.right: parent.right; anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.active ? "✓" : ""
                    color: panel.accent; font.pixelSize: 12
                }
                MouseArea {
                    id: devMa
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: Quickshell.execDetached(["wpctl", "set-default", modelData.id])
                }
            }
        }
        Text {
            visible: panel.devices.length === 0
            text: "No devices found"
            color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.5); font.pixelSize: 11
        }
    }

    // Volume slider
    Column {
        width: parent.width
        spacing: 4
        Item {
            width: parent.width
            height: 14
            Text { anchors.left: parent.left; text: panel.tab === 0 ? "Output volume" : "Input volume"; color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.7); font.pixelSize: 11 }
            Text { anchors.right: parent.right; text: Math.round(panel.vol * 100) + "%"; color: panel.fg; font.pixelSize: 11; font.family: "monospace" }
        }
        Rectangle {
            id: track
            width: parent.width
            height: 6
            radius: 3
            color: sys.dark
            Rectangle {
                height: parent.height; radius: 3
                width: parent.width * Math.min(1, panel.vol)
                color: panel.accent
            }
            MouseArea {
                anchors.fill: parent
                anchors.topMargin: -8; anchors.bottomMargin: -8
                cursorShape: Qt.PointingHandCursor
                onPressed: function(m) { setVol(m.x) }
                onPositionChanged: function(m) { if (pressed) setVol(m.x) }
                function setVol(x) {
                    const v = Math.max(0, Math.min(1, x / track.width));
                    Quickshell.execDetached(["wpctl", "set-volume", panel.targetId, v.toFixed(2)]);
                }
            }
        }
    }
}
