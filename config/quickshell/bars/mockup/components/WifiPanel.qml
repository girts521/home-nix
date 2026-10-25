import Quickshell
import QtQuick

BarPanel {
    id: panel
    required property var sys

    bg: sys.bg; fg: sys.fg; accent: sys.accent; secondary: sys.secondary
    panelWidth: 320

    signal scanRequested()

    // Header: title, scan button, enable switch
    Item {
        width: parent.width
        height: 28
        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            Text { text: "≋"; color: panel.accent; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter }
            Text { text: "Wi-Fi"; color: panel.fg; font.bold: true; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
        }
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10
            Rectangle {
                height: 20; width: scanText.implicitWidth + 14; radius: 4
                color: scanMa.containsMouse ? Qt.rgba(panel.accent.r, panel.accent.g, panel.accent.b, 0.3) : "transparent"
                Text { id: scanText; anchors.centerIn: parent; text: "⟳ Scan"; color: panel.fg; font.pixelSize: 11 }
                MouseArea { id: scanMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: { Quickshell.execDetached(["nmcli", "dev", "wifi", "rescan"]); panel.scanRequested(); } }
            }
            Toggle {
                id: wifiSwitch
                on: sys.wifiOn
                onToggled: Quickshell.execDetached(["nmcli", "radio", "wifi", wifiSwitch.on ? "on" : "off"])
            }
        }
    }

    // Connected network
    Column {
        width: parent.width
        spacing: 4
        Text { text: "CONNECTED"; color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.5); font.pixelSize: 10; font.bold: true }
        Rectangle {
            width: parent.width
            height: visible ? 62 : 0
            visible: sys.wifiSsid !== "Not connected"
            radius: 8
            color: Qt.rgba(panel.secondary.r, panel.secondary.g, panel.secondary.b, 0.2)
            border.width: 1
            border.color: Qt.rgba(panel.secondary.r, panel.secondary.g, panel.secondary.b, 0.4)
            Column {
                anchors.left: parent.left; anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                Text { text: sys.wifiSsid; color: panel.fg; font.bold: true; font.pixelSize: 12 }
                Text { text: "Connected · " + sys.wifiSignal + "%"; color: "#34d399"; font.pixelSize: 10 }
            }
            Rectangle {
                anchors.right: parent.right; anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                width: 84; height: 22; radius: 4; color: Qt.rgba(0.04, 0.08, 0.2, 1)
                Text { anchors.centerIn: parent; text: "Disconnect"; color: panel.fg; font.pixelSize: 10 }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: Quickshell.execDetached(["nmcli", "connection", "down", "id", sys.wifiSsid]) }
            }
        }
    }

    // Available networks
    Column {
        width: parent.width
        spacing: 2
        Text { text: "AVAILABLE"; color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.5); font.pixelSize: 10; font.bold: true }
        Repeater {
            model: sys.wifiNetworks.filter(n => !n.active).slice(0, 6)
            Rectangle {
                required property var modelData
                width: parent.width
                height: 30
                radius: 6
                color: rowMa.containsMouse ? Qt.rgba(panel.accent.r, panel.accent.g, panel.accent.b, 0.2) : "transparent"
                Row {
                    anchors.left: parent.left; anchors.leftMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    Text { text: modelData.security === "Open" ? "" : "🔒"; font.pixelSize: 10; color: panel.fg; opacity: 0.6; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: modelData.ssid; color: panel.fg; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                }
                Text {
                    anchors.right: parent.right; anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.signal + "%"
                    color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.5); font.pixelSize: 10; font.family: "monospace"
                }
                MouseArea { id: rowMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: Quickshell.execDetached(["nmcli", "device", "wifi", "connect", modelData.ssid]) }
            }
        }
    }
}
