import Quickshell
import QtQuick

BarPanel {
    id: panel
    required property var sys

    bg: sys.bg; fg: sys.fg; accent: sys.accent; secondary: sys.secondary
    panelWidth: 320

    Item {
        width: parent.width
        height: 28
        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            Text { text: "ᛒ"; color: panel.accent; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter }
            Text { text: "Bluetooth"; color: panel.fg; font.bold: true; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
        }
        Toggle {
            id: btSwitch
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            accent: panel.accent
            on: sys.btOn
            onToggled: Quickshell.execDetached(["bluetoothctl", "power", btSwitch.on ? "on" : "off"])
        }
    }

    Column {
        width: parent.width
        spacing: 2
        Text { text: "PAIRED"; color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.5); font.pixelSize: 10; font.bold: true }
        Repeater {
            model: sys.btDevices
            Rectangle {
                required property var modelData
                width: parent.width
                height: 38
                radius: 6
                color: devMa.containsMouse ? Qt.rgba(panel.accent.r, panel.accent.g, panel.accent.b, 0.2) : "transparent"
                Column {
                    anchors.left: parent.left; anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    Text { text: modelData.name; color: modelData.connected ? panel.fg : Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.6); font.bold: true; font.pixelSize: 12 }
                    Text { text: modelData.connected ? "Connected" : "Not connected"; color: modelData.connected ? "#34d399" : Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.4); font.pixelSize: 10 }
                }
                Rectangle {
                    anchors.right: parent.right; anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: connText.implicitWidth + 14; height: 20; radius: 4; color: Qt.rgba(0.04, 0.08, 0.2, 1)
                    Text { id: connText; anchors.centerIn: parent; text: modelData.connected ? "Disconnect" : "Connect"; color: panel.fg; font.pixelSize: 10 }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["bluetoothctl", modelData.connected ? "disconnect" : "connect", modelData.mac]) }
                }
                MouseArea { id: devMa; anchors.fill: parent; hoverEnabled: true; z: -1 }
            }
        }
        Text {
            visible: sys.btDevices.length === 0
            text: sys.btOn ? "No paired devices" : "Bluetooth is off"
            color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.5); font.pixelSize: 11
        }
    }
}
