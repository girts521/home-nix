import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Compact, expandable controls using NetworkManager, BlueZ and WirePlumber CLIs.
PopupWindow {
    id: popup

    property var barWindow
    property color backgroundColor: "#122957"
    property color foregroundColor: "#c6cff5"
    property color accentColor: "#8e81d9"
    property color secondaryColor: "#3f5ac8"

    property bool wifiEnabled: false
    property string wifiName: "Checking network…"
    property var wifiList: []
    property var savedNetworks: []
    property bool bluetoothEnabled: false
    property string bluetoothName: "No device connected"
    property var bluetoothList: []
    property string audioTab: "output"
    property bool networkDetails: false
    property bool bluetoothDetails: false
    property string deviceMenuTab: ""
    property var audioOutputs: []
    property var audioInputs: []
    property string outputId: "@DEFAULT_AUDIO_SINK@"
    property string inputId: "@DEFAULT_AUDIO_SOURCE@"
    property real volume: 0.5
    property real inputVolume: 0.5
    property bool muted: false
    property bool inputMuted: false

    implicitWidth: 370
    implicitHeight: 396 + ((networkDetails || bluetoothDetails) ? 80 : 0) + (deviceMenuTab !== "" ? 50 : 0)
    visible: false
    color: "transparent"
    grabFocus: true
    anchor.window: barWindow
    anchor.rect.x: barWindow ? barWindow.width - implicitWidth - 8 : 0
    anchor.rect.y: barWindow ? barWindow.height + 6 : 0

    function refresh() {
        wifiState.running = true;
        wifiConnections.running = true;
        savedNetworksProcess.running = true;
        bluetoothState.running = true;
        bluetoothDevices.running = true;
        audioStatus.running = true;
        outputVolumeState.running = true;
        inputVolumeState.running = true;
    }

    function toggle() {
        visible = !visible;
        if (visible) {
            refresh();
            panel.opacity = 0;
            opening.restart();
        }
    }

    Process {
        id: wifiState
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: popup.wifiEnabled = this.text.trim() === "enabled"
        }
    }

    Process {
        id: wifiConnections
        command: ["nmcli", "-t", "-f", "ACTIVE,SSID", "dev", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n").filter(line => line.length > 0);
                const active = lines.find(line => line.startsWith("yes:"));
                popup.wifiName = active ? active.slice(4).replace(/\\:/g, ":") : "Not connected";
                if (!popup.wifiEnabled) popup.wifiName = "Turned off";
                popup.wifiList = lines.map(line => {
                    const parts = line.split(":");
                    return { active: parts[0] === "yes", ssid: parts.slice(1).join(":").replace(/\\:/g, ":") };
                }).filter(item => item.ssid.length > 0);
            }
        }
    }

    Process {
        id: savedNetworksProcess
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                popup.savedNetworks = this.text.trim().split("\n").filter(line => line.includes(":802-11-wireless") || line.includes(":wifi"))
                    .map(line => line.slice(0, line.lastIndexOf(":" )).replace(/\\:/g, ":"))
                    .filter(name => name.length > 0);
            }
        }
    }

    Process {
        id: bluetoothState
        command: ["bluetoothctl", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const match = this.text.match(/^\s*Powered:\s*(yes|no)/m);
                popup.bluetoothEnabled = match ? match[1] === "yes" : false;
            }
        }
    }

    Process {
        id: bluetoothDevices
        command: ["sh", "-c", "bluetoothctl devices Paired | while read -r _ mac name; do info=$(bluetoothctl info \"$mac\"); printf '%s|%s|%s\\n' \"$mac\" \"$name\" \"$(printf '%s\\n' \"$info\" | awk '/Connected:/ {print $2; exit}')\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const list = this.text.trim().split("\n").filter(line => line.length > 0).map(line => {
                    const parts = line.split("|");
                    return { mac: parts[0], name: parts[1] || parts[0], connected: parts[2] === "yes" };
                });
                popup.bluetoothList = list.map(device => ({ ...device, active: false }));
                const connected = list.find(device => device.connected);
                popup.bluetoothName = connected ? connected.name : "No device connected";
                if (!popup.bluetoothEnabled) popup.bluetoothName = "Turned off";
            }
        }
    }

    Process {
        id: audioStatus
        command: ["sh", "-c", "wpctl status | sed -n '/Sinks:/,/Sink endpoints:/p; /Sources:/,/Source endpoints:/p'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const outputs = [];
                const inputs = [];
                let section = "";
                for (const line of this.text.split("\n")) {
                    if (line.includes("Sinks:")) { section = "output"; continue; }
                    if (line.includes("Sources:")) { section = "input"; continue; }
                    if (line.includes("endpoints:")) { section = ""; continue; }
                    const match = line.match(/(\*?)\s*(\d+)\.\s+(.+)$/);
                    if (!match) continue;
                    const device = { id: match[2], name: match[3].split(" [")[0].trim(), active: match[1] === "*" };
                    if (section === "output") outputs.push(device);
                    if (section === "input") inputs.push(device);
                }
                popup.audioOutputs = outputs;
                popup.audioInputs = inputs;
                const defaultOutput = outputs.find(device => device.active);
                const defaultInput = inputs.find(device => device.active);
                if (defaultOutput) popup.outputId = defaultOutput.id;
                if (defaultInput) popup.inputId = defaultInput.id;
            }
        }
    }

    Process {
        id: outputVolumeState
        command: ["wpctl", "get-volume", popup.outputId]
        stdout: StdioCollector {
            onStreamFinished: {
                const match = this.text.match(/Volume:\s*([0-9.]+)/);
                if (match) popup.volume = Math.max(0, Math.min(1.5, Number(match[1])));
                popup.muted = this.text.indexOf("[MUTED]") >= 0;
            }
        }
    }

    Process {
        id: inputVolumeState
        command: ["wpctl", "get-volume", popup.inputId]
        stdout: StdioCollector {
            onStreamFinished: {
                const match = this.text.match(/Volume:\s*([0-9.]+)/);
                if (match) popup.inputVolume = Math.max(0, Math.min(1.5, Number(match[1])));
                popup.inputMuted = this.text.indexOf("[MUTED]") >= 0;
            }
        }
    }

    Process { id: wifiCommand }
    Process { id: bluetoothCommand }
    Process { id: audioCommand }

    Timer { id: poll; interval: 5000; repeat: true; running: popup.visible; onTriggered: popup.refresh() }
    Timer { id: refreshSoon; interval: 700; repeat: false; onTriggered: popup.refresh() }
    Timer { id: opening; interval: 160; repeat: false; onTriggered: { panel.opacity = 1; panel.y = 0; } }

    Rectangle {
        id: panel
        anchors.fill: parent
        radius: 17
        color: Qt.rgba(popup.backgroundColor.r, popup.backgroundColor.g, popup.backgroundColor.b, 0.98)
        border.width: 1
        border.color: Qt.rgba(popup.foregroundColor.r, popup.foregroundColor.g, popup.foregroundColor.b, 0.14)
        opacity: 0
        y: -5
        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 11

            RowLayout {
                Layout.fillWidth: true
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Text { text: "Quick controls"; color: popup.foregroundColor; font.pixelSize: 17; font.bold: true }
                    Text { text: "Network, Bluetooth & sound"; color: Qt.rgba(popup.foregroundColor.r, popup.foregroundColor.g, popup.foregroundColor.b, 0.62); font.pixelSize: 11 }
                }
                Rectangle {
                    width: 29; height: 29; radius: 9
                    color: closeMouse.containsMouse ? popup.secondaryColor : "transparent"
                    Text { anchors.centerIn: parent; text: "×"; color: popup.foregroundColor; font.pixelSize: 19 }
                    MouseArea { id: closeMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: popup.visible = false }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 9
                ControlTile {
                    Layout.fillWidth: true
                    title: "Wi-Fi"; detail: popup.wifiName; glyph: "◉"
                    enabledState: popup.wifiEnabled; backgroundColor: popup.backgroundColor
                    foregroundColor: popup.foregroundColor; accentColor: popup.accentColor
                    onClicked: { wifiCommand.exec(["nmcli", "radio", "wifi", popup.wifiEnabled ? "off" : "on"]); refreshSoon.restart(); }
                }
                ControlTile {
                    Layout.fillWidth: true
                    title: "Bluetooth"; detail: popup.bluetoothName; glyph: "ᛒ"
                    enabledState: popup.bluetoothEnabled; backgroundColor: popup.backgroundColor
                    foregroundColor: popup.foregroundColor; accentColor: popup.accentColor
                    onClicked: { bluetoothCommand.exec(["bluetoothctl", "power", popup.bluetoothEnabled ? "off" : "on"]); refreshSoon.restart(); }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Rectangle {
                    Layout.fillWidth: true; height: 27; radius: 8
                    color: networkExpand.containsMouse ? popup.secondaryColor : "transparent"
                    Text { anchors.centerIn: parent; text: popup.networkDetails ? "Wi-Fi networks  ⌄" : "Wi-Fi networks  ›"; color: popup.foregroundColor; font.pixelSize: 10; font.bold: true }
                    MouseArea { id: networkExpand; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: popup.networkDetails = !popup.networkDetails }
                }
                Rectangle {
                    Layout.fillWidth: true; height: 27; radius: 8
                    color: bluetoothExpand.containsMouse ? popup.secondaryColor : "transparent"
                    Text { anchors.centerIn: parent; text: popup.bluetoothDetails ? "Bluetooth devices  ⌄" : "Bluetooth devices  ›"; color: popup.foregroundColor; font.pixelSize: 10; font.bold: true }
                    MouseArea { id: bluetoothExpand; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: popup.bluetoothDetails = !popup.bluetoothDetails }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 118 + (deviceMenuTab !== "" ? 72 : 0)
                radius: 13
                color: Qt.rgba(popup.foregroundColor.r, popup.foregroundColor.g, popup.foregroundColor.b, 0.055)
                border.width: 1
                border.color: Qt.rgba(popup.foregroundColor.r, popup.foregroundColor.g, popup.foregroundColor.b, 0.07)
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 10; spacing: 6
                    RowLayout {
                        Layout.fillWidth: true
                        Rectangle { width: 27; height: 27; radius: 9; color: Qt.rgba(popup.accentColor.r, popup.accentColor.g, popup.accentColor.b, 0.18); Text { anchors.centerIn: parent; text: "♫"; color: popup.accentColor; font.pixelSize: 16 } }
                        Text { Layout.fillWidth: true; text: "Audio"; color: popup.foregroundColor; font.pixelSize: 12; font.bold: true }
                        Row {
                            spacing: 3
                            Repeater {
                                model: [{ key: "output", label: "Output" }, { key: "input", label: "Input" }]
                                delegate: Rectangle {
                                    required property var modelData
                                    width: modelData.key === "output" ? 48 : 39; height: 24; radius: 7
                                    color: popup.audioTab === modelData.key ? popup.secondaryColor : "transparent"
                                    Text { anchors.centerIn: parent; text: modelData.label; color: popup.foregroundColor; font.pixelSize: 9 }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: popup.audioTab = modelData.key }
                                }
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 7
                        Text { text: popup.audioTab === "output" ? (popup.muted ? "Muted" : "Volume") : (popup.inputMuted ? "Mic muted" : "Mic level"); color: Qt.rgba(popup.foregroundColor.r, popup.foregroundColor.g, popup.foregroundColor.b, 0.68); font.pixelSize: 10 }
                        Slider {
                            id: audioSlider
                            Layout.fillWidth: true; from: 0; to: 1.5
                            value: popup.audioTab === "output" ? popup.volume : popup.inputVolume
                            onMoved: {
                                if (popup.audioTab === "output") { popup.volume = value; audioCommand.exec(["wpctl", "set-volume", popup.outputId, value.toFixed(2)]); }
                                else { popup.inputVolume = value; audioCommand.exec(["wpctl", "set-volume", popup.inputId, value.toFixed(2)]); }
                            }
                        }
                        Text { text: Math.round((popup.audioTab === "output" ? popup.volume : popup.inputVolume) * 100) + "%"; color: popup.foregroundColor; font.pixelSize: 10; font.bold: true }
                        Rectangle {
                            width: 25; height: 25; radius: 7
                            color: muteMouse.containsMouse ? popup.secondaryColor : "transparent"
                            Text { anchors.centerIn: parent; text: popup.audioTab === "output" ? (popup.muted ? "×" : "◖") : (popup.inputMuted ? "×" : "M"); color: popup.foregroundColor; font.pixelSize: 12 }
                            MouseArea {
                                id: muteMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { audioCommand.exec(["wpctl", "set-mute", popup.audioTab === "output" ? popup.outputId : popup.inputId, "toggle"]); refreshSoon.restart(); }
                            }
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true; height: 25; radius: 7
                        color: deviceMenu.containsMouse ? popup.secondaryColor : Qt.rgba(popup.foregroundColor.r, popup.foregroundColor.g, popup.foregroundColor.b, 0.06)
                        Text {
                            anchors.left: parent.left; anchors.leftMargin: 8; anchors.right: parent.right; anchors.rightMargin: 6; anchors.verticalCenter: parent.verticalCenter
                            text: {
                                const devices = popup.audioTab === "output" ? popup.audioOutputs : popup.audioInputs;
                                const selected = devices.find(device => device.id === (popup.audioTab === "output" ? popup.outputId : popup.inputId));
                                return (popup.audioTab === "output" ? "Output: " : "Input: ") + (selected ? selected.name : "System default") + "   ▾";
                            }
                            color: popup.foregroundColor; font.pixelSize: 9; elide: Text.ElideRight
                        }
                        MouseArea { id: deviceMenu; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: popup.deviceMenuTab = popup.deviceMenuTab === popup.audioTab ? "" : popup.audioTab }
                    }
                    Repeater {
                        model: popup.deviceMenuTab === popup.audioTab ? (popup.audioTab === "output" ? popup.audioOutputs : popup.audioInputs) : []
                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true; height: 23; radius: 6
                            color: menuMouse.containsMouse ? popup.secondaryColor : "transparent"
                            Text { anchors.left: parent.left; anchors.leftMargin: 7; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: (modelData.active ? "✓  " : "") + modelData.name; color: popup.foregroundColor; font.pixelSize: 9; elide: Text.ElideRight }
                            MouseArea {
                                id: menuMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    audioCommand.exec(["wpctl", "set-default", modelData.id]);
                                    if (popup.audioTab === "output") popup.outputId = modelData.id;
                                    else popup.inputId = modelData.id;
                                    popup.deviceMenuTab = "";
                                    refreshSoon.restart();
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: (popup.networkDetails || popup.bluetoothDetails) ? 86 : 27
                radius: 11
                color: Qt.rgba(popup.foregroundColor.r, popup.foregroundColor.g, popup.foregroundColor.b, 0.045)
                clip: true
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 8; spacing: 3
                    Text {
                        Layout.fillWidth: true
                        visible: popup.networkDetails || popup.bluetoothDetails
                        text: popup.networkDetails ? "AVAILABLE NETWORKS — saved connections" : "PAIRED DEVICES — tap to connect / disconnect"
                        color: popup.accentColor; font.pixelSize: 8; font.bold: true; font.letterSpacing: 1
                    }
                    Repeater {
                        model: popup.networkDetails ? popup.savedNetworks.slice(0, 3).map(name => ({ ssid: name, active: name === popup.wifiName })) : (popup.bluetoothDetails ? popup.bluetoothList.slice(0, 3) : [])
                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true; height: 19; radius: 5
                            color: detailItemMouse.containsMouse ? popup.secondaryColor : "transparent"
                            Text {
                                anchors.left: parent.left; anchors.leftMargin: 6; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                text: popup.networkDetails
                                    ? ((modelData.active ? "✓  " : "◉  ") + modelData.ssid)
                                    : ((modelData.connected ? "✓  " : "ᛒ  ") + modelData.name + (modelData.connected ? " · Connected" : ""))
                                color: popup.foregroundColor; font.pixelSize: 9; elide: Text.ElideRight
                            }
                            MouseArea {
                                id: detailItemMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (popup.networkDetails) {
                                        if (modelData.active) return;
                                        wifiCommand.exec(["nmcli", "connection", "up", "id", modelData.ssid]);
                                    } else {
                                        bluetoothCommand.exec(["bluetoothctl", modelData.connected ? "disconnect" : "connect", modelData.mac]);
                                    }
                                    refreshSoon.restart();
                                }
                            }
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: !popup.networkDetails && !popup.bluetoothDetails
                        text: "Expand Wi-Fi or Bluetooth for device controls"
                        color: Qt.rgba(popup.foregroundColor.r, popup.foregroundColor.g, popup.foregroundColor.b, 0.52); font.pixelSize: 9; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: (popup.networkDetails && popup.savedNetworks.length === 0) || (popup.bluetoothDetails && popup.bluetoothList.length === 0)
                        text: popup.networkDetails ? "No saved networks found" : "No paired devices found"
                        color: Qt.rgba(popup.foregroundColor.r, popup.foregroundColor.g, popup.foregroundColor.b, 0.52); font.pixelSize: 9
                    }
                }
            }
        }
    }
}
