import Quickshell
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
    contentInset: 12
    contentSpacing: 12
    cornerRadius: 12

    Item {
        width: parent.width
        height: 32

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            Icon { name: "bluetooth"; tone: "accent"; size: 16 }
            Text { text: "Bluetooth"; color: panel.fg; font.bold: true; font.pixelSize: 13; font.family: panel.uiFont }
        }

        Toggle {
            id: btSwitch
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            accent: panel.accent
            on: sys.btOn
            onToggled: Quickshell.execDetached(["bluetoothctl", "power", btSwitch.on ? "on" : "off"])
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
        spacing: 4

        Text {
            text: "CONNECTED"
            color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.5)
            font.pixelSize: 10
            font.bold: true
            font.family: panel.uiFont
        }

        Repeater {
            model: sys.btDevices.filter(d => d.connected)
            Rectangle {
                required property var modelData
                width: parent.width
                height: 40
                radius: 8
                color: deviceMa.containsMouse ? Qt.rgba(panel.accent.r, panel.accent.g, panel.accent.b, 0.2) : "transparent"

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    Icon { anchors.verticalCenter: parent.verticalCenter; name: "headphones"; tone: "fg"; size: 16 }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Text { text: modelData.name; color: panel.fg; font.bold: true; font.pixelSize: 12; font.family: panel.uiFont; elide: Text.ElideRight; width: 175 }
                        Text { text: "Audio · Connected"; color: "#34d399"; font.pixelSize: 10; font.family: panel.uiFont }
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    Icon { anchors.verticalCenter: parent.verticalCenter; name: "battery-medium"; tone: "emerald"; size: 14 }
                    Text { anchors.verticalCenter: parent.verticalCenter; text: modelData.battery !== undefined ? modelData.battery + "%" : "—%"; color: "#34d399"; font.pixelSize: 10; font.family: "monospace" }
                }

                MouseArea { id: deviceMa; anchors.fill: parent; hoverEnabled: true; z: -1 }
            }
        }
    }

    Column {
        width: parent.width
        spacing: 4

        Text {
            text: "PAIRED"
            color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.5)
            font.pixelSize: 10
            font.bold: true
            font.family: panel.uiFont
        }

        Repeater {
            model: sys.btDevices.filter(d => !d.connected)
            Rectangle {
                required property var modelData
                width: parent.width
                height: 38
                radius: 8
                color: devMa.containsMouse ? Qt.rgba(panel.accent.r, panel.accent.g, panel.accent.b, 0.2) : "transparent"

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    Icon { anchors.verticalCenter: parent.verticalCenter; name: "keyboard"; tone: "muted"; size: 16 }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Text { text: modelData.name; color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.6); font.bold: true; font.pixelSize: 12; font.family: panel.uiFont; elide: Text.ElideRight; width: 175 }
                        Text { text: "Not connected"; color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.4); font.pixelSize: 10; font.family: panel.uiFont }
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    width: connText.implicitWidth + 16
                    height: 20
                    radius: 4
                    color: panel.dark
                    Text { id: connText; anchors.centerIn: parent; text: "Connect"; color: panel.fg; font.pixelSize: 10; font.family: panel.uiFont }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["bluetoothctl", "connect", modelData.mac])
                    }
                }

                MouseArea { id: devMa; anchors.fill: parent; hoverEnabled: true; z: -1 }
            }
        }
    }

    Rectangle {
        width: parent.width
        height: 34
        radius: 8
        color: pairMa.containsMouse ? Qt.rgba(panel.secondary.r, panel.secondary.g, panel.secondary.b, 0.2) : "transparent"
        border.width: 1
        border.color: Qt.rgba(panel.accent.r, panel.accent.g, panel.accent.b, 0.4)
        Row {
            anchors.centerIn: parent
            spacing: 5
            Icon { name: "plus"; tone: "accent"; size: 14 }
            Text { text: "Pair new device"; color: panel.fg; font.pixelSize: 11; font.family: panel.uiFont }
        }
        MouseArea { id: pairMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["bluetoothctl", "scan", "on"]) }
    }
}
