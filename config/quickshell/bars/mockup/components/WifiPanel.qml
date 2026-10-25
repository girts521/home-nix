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
    signal scanRequested()

    // Reference header/actions, followed by the network search field.
    Item {
        width: parent.width
        height: 32

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            Icon { name: "wifi"; tone: "accent"; size: 16 }
            Text { text: "Wi-Fi"; color: panel.fg; font.bold: true; font.pixelSize: 13; font.family: panel.uiFont }
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Rectangle {
                width: scanRow.implicitWidth + 12
                height: 20
                radius: 4
                color: scanMa.containsMouse ? Qt.rgba(panel.secondary.r, panel.secondary.g, panel.secondary.b, 0.3) : "transparent"
                Row {
                    id: scanRow
                    anchors.centerIn: parent
                    spacing: 4
                    Icon {
                        name: "refresh-cw"
                        tone: "accent"
                        size: 12
                        RotationAnimation on rotation {
                            running: sys.wifiScanning
                            from: 0
                            to: 360
                            duration: 800
                            loops: Animation.Infinite
                        }
                    }
                    Text { text: "Scan"; color: panel.fg; font.pixelSize: 11; font.family: panel.uiFont }
                }
                MouseArea {
                    id: scanMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        sys.scanWifi();
                        panel.scanRequested();
                    }
                }
            }

            Toggle {
                id: wifiSwitch
                on: sys.wifiOn
                accent: panel.accent
                onToggled: Quickshell.execDetached(["nmcli", "radio", "wifi", wifiSwitch.on ? "on" : "off"])
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.1)
        }
    }

    Rectangle {
        width: parent.width
        height: 26
        radius: 4
        color: panel.dark
        border.width: 1
        border.color: Qt.rgba(panel.secondary.r, panel.secondary.g, panel.secondary.b, 0.4)

        Icon {
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            name: "search"
            tone: "muted"
            size: 14
        }
        TextInput {
            id: search
            anchors.left: parent.left
            anchors.leftMargin: 28
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            color: panel.fg
            font.pixelSize: 12
            font.family: panel.uiFont
            clip: true
            Text {
                anchors.fill: parent
                visible: !search.text && !search.activeFocus
                text: "Search networks..."
                color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.5)
                font: search.font
            }
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

        Rectangle {
            id: connectedCard
            width: parent.width
            height: visible ? 88 : 0
            radius: 8
            visible: sys.wifiSsid !== "Not connected"
            color: Qt.rgba(panel.secondary.r, panel.secondary.g, panel.secondary.b, 0.2)
            border.width: 1
            border.color: Qt.rgba(panel.secondary.r, panel.secondary.g, panel.secondary.b, 0.4)

            Column {
                anchors.fill: parent
                anchors.margins: 9
                spacing: 6

                Item {
                    width: parent.width
                    height: 24
                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8
                        Icon { anchors.verticalCenter: parent.verticalCenter; name: "wifi"; tone: "emerald"; size: 16 }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            Text { text: sys.wifiSsid; color: panel.fg; font.bold: true; font.pixelSize: 12; font.family: panel.uiFont; elide: Text.ElideRight; width: 170 }
                            Text { text: "Connected" + (sys.wifiBand ? " · " + sys.wifiBand : ""); color: "#34d399"; font.pixelSize: 10; font.family: panel.uiFont }
                        }
                    }
                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Repeater {
                            model: 4
                            Rectangle {
                                required property int index
                                width: 3
                                height: 4 + index * 2
                                radius: 1
                                anchors.bottom: parent.bottom
                                color: sys.wifiSignal >= (index + 1) * 25 ? "#34d399" : Qt.rgba(0.2, 0.8, 0.5, 0.25)
                            }
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: 0
                    Repeater {
                        model: [sys.wifiIp, sys.wifiSpeed, "—"]
                        Text {
                            required property string modelData
                            width: parent.width / 3
                            text: modelData
                            color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.7)
                            font.pixelSize: 10
                            font.family: "monospace"
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 18
                    radius: 4
                    color: panel.dark
                    Text { anchors.centerIn: parent; text: "Disconnect"; color: panel.fg; font.pixelSize: 10; font.family: panel.uiFont }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["nmcli", "connection", "down", "id", sys.wifiSsid])
                    }
                }
            }
        }
    }

    Column {
        width: parent.width
        spacing: 4

        Text {
            text: "AVAILABLE"
            color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.5)
            font.pixelSize: 10
            font.bold: true
            font.family: panel.uiFont
        }

        Repeater {
            model: sys.wifiNetworks.filter(n => !n.active && (!search.text || n.ssid.toLowerCase().includes(search.text.toLowerCase()))).slice(0, 6)
            Rectangle {
                required property var modelData
                width: parent.width
                height: 28
                radius: 8
                color: rowMa.containsMouse ? Qt.rgba(panel.accent.r, panel.accent.g, panel.accent.b, 0.2) : "transparent"

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    Icon { name: modelData.security === "Open" ? "wifi-off" : "lock"; tone: "muted"; size: 12 }
                    Text {
                        text: modelData.ssid
                        color: panel.fg
                        font.pixelSize: 12
                        font.family: panel.uiFont
                        elide: Text.ElideRight
                        width: 125
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    Row {
                        height: 12
                        spacing: 2
                        Repeater {
                            model: 4
                            Rectangle {
                                required property int index
                                width: 3
                                height: 4 + index * 2
                                radius: 1
                                anchors.bottom: parent.bottom
                                color: modelData.signal >= (index + 1) * 25 ? panel.accent : Qt.rgba(panel.accent.r, panel.accent.g, panel.accent.b, 0.25)
                            }
                        }
                    }
                    Rectangle {
                        width: 52
                        height: 20
                        radius: 4
                        color: panel.dark
                        Text { anchors.centerIn: parent; text: "Connect"; color: panel.fg; font.pixelSize: 10; font.family: panel.uiFont }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Quickshell.execDetached(["nmcli", "device", "wifi", "connect", modelData.ssid])
                        }
                    }
                }

                MouseArea { id: rowMa; anchors.fill: parent; hoverEnabled: true; z: -1 }
            }
        }
    }
}
