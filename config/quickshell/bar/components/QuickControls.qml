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
    property var wifiResults: []
    property bool wifiScanning: false
    property bool wifiScanPending: false
    property string wifiScanMessage: ""
    property string wifiScanError: ""
    property var savedNetworks: []
    property bool bluetoothEnabled: false
    property string bluetoothName: "No device connected"
    property var bluetoothList: []
    property var bluetoothFound: []
    property bool bluetoothScanning: false
    property bool bluetoothScanPending: false
    property string bluetoothScanMessage: ""
    property string bluetoothScanError: ""
    property var calendarPopup: null
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
    implicitHeight: 435 + ((networkDetails || bluetoothDetails) ? 92 : 0) + (deviceMenuTab !== "" ? 78 : 0)
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
        if (visible) {
            opening.stop();
            closing.restart();
            return;
        }
        closing.stop();
        if (calendarPopup) calendarPopup.hide();
        refresh();
        panel.opacity = 0;
        panel.offsetY = -5;
        visible = true;
        opening.restart();
    }

    function hide() {
        opening.stop();
        closing.stop();
        panel.opacity = 0;
        visible = false;
    }

    function startWifiScan() {
        wifiScanMessage = "";
        wifiScanning = true;
        wifiScanTimeout.restart();
        if (!wifiEnabled) {
            wifiScanPending = true;
            wifiCommand.exec(["nmcli", "radio", "wifi", "on"]);
            wifiScanAfterEnable.restart();
            return;
        }
        wifiScanPending = false;
        wifiResults = [];
        wifiScanProcess.running = true;
    }

    function startBluetoothScan() {
        bluetoothScanMessage = "";
        bluetoothScanning = true;
        bluetoothStopTimer.restart();
        if (!bluetoothEnabled) {
            bluetoothScanPending = true;
            bluetoothCommand.exec(["bluetoothctl", "power", "on"]);
            bluetoothScanAfterEnable.restart();
            return;
        }
        bluetoothScanPending = false;
        bluetoothFound = [];
        bluetoothList = [];
        bluetoothScanProcess.running = true;
    }

    function finishWifiScan() {
        if (wifiScanning && wifiResults.length === 0 && wifiScanMessage.length === 0)
            popup.wifiScanMessage = popup.wifiScanError || (wifiEnabled ? "No nearby networks found" : "Wi-Fi could not be enabled");
        wifiScanning = false;
        wifiScanPending = false;
        wifiScanTimeout.stop();
    }

    function cancelWifiScan() {
        wifiScanning = false;
        wifiScanPending = false;
        wifiScanTimeout.stop();
        wifiScanAfterEnable.stop();
        wifiScanProcess.running = false;
    }

    function finishBluetoothScan() {
        if (!bluetoothScanning && !bluetoothScanPending) return;
        if (bluetoothFound.length === 0 && bluetoothScanMessage.length === 0)
            bluetoothScanMessage = bluetoothEnabled ? "No nearby devices found" : "Bluetooth could not be enabled";
        bluetoothScanning = false;
        bluetoothScanPending = false;
        bluetoothStopTimer.stop();
        if (bluetoothScanProcess.running) {
            bluetoothScanProcess.write("scan off\n");
            bluetoothProcessCleanup.restart();
        }
        bluetoothDevices.running = true;
    }

    function parseWifiLine(line) {
        const fields = [];
        let field = "";
        let escaped = false;
        for (const ch of line) {
            if (escaped) { field += ch; escaped = false; }
            else if (ch === "\\") escaped = true;
            else if (ch === ":") { fields.push(field); field = ""; }
            else field += ch;
        }
        fields.push(field);
        if (fields.length < 4 || !fields[1]) return null;
        return { active: fields[0] === "*", ssid: fields[1], signal: Number(fields[2]) || 0, security: fields[3] || "Open" };
    }

    function handleBluetoothLine(line) {
        let match = line.match(/Device\s+([0-9A-F:]{17})\s+(.+)/i);
        if (!match) match = line.match(/\[NEW\]\s+Device\s+([0-9A-F:]{17})\s+(.+)/i);
        if (!match) match = line.match(/\[CHG\]\s+Device\s+([0-9A-F:]{17})\s+Name:\s+(.+)/i);
        if (!match) match = line.match(/\[CHG\]\s+Device\s+([0-9A-F:]{17})\s+Alias:\s+(.+)/i);
        if (!match) return;
        const device = { mac: match[1], name: match[2].trim(), connected: false, active: true };
        const index = bluetoothFound.findIndex(item => item.mac === device.mac);
        const updated = bluetoothFound.slice();
        if (index >= 0) updated[index] = device;
        else updated.unshift(device);
        bluetoothFound = updated;
        bluetoothList = updated.concat(bluetoothList.filter(item => !updated.some(found => found.mac === item.mac)));
    }

    function setAudioVolume(value) {
        const bounded = Math.max(0, Math.min(1.5, Number(value)));
        const id = popup.audioTab === "output" ? popup.outputId : popup.inputId;
        if (popup.audioTab === "output") popup.volume = bounded;
        else popup.inputVolume = bounded;
        audioCommand.exec(["wpctl", "set-volume", id, bounded.toFixed(2)]);
    }

    Process {
        id: wifiState
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                popup.wifiEnabled = this.text.trim() === "enabled";
                if (popup.wifiEnabled && popup.wifiScanPending) popup.startWifiScan();
            }
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
                if (popup.bluetoothEnabled && popup.bluetoothScanPending) popup.startBluetoothScan();
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
                const paired = list.map(device => ({ mac: device.mac, name: device.name, connected: device.connected, active: false }));
                popup.bluetoothList = paired.concat(popup.bluetoothFound.filter(found => !paired.some(device => device.mac === found.mac)));
                const connected = list.find(device => device.connected);
                popup.bluetoothName = connected ? connected.name : "No device connected";
                if (!popup.bluetoothEnabled) popup.bluetoothName = "Turned off";
            }
        }
    }

    Process {
        id: wifiScanProcess
        command: ["nmcli", "-t", "--escape", "yes", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list", "--rescan", "yes"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split("\n").filter(line => line.length > 0);
                popup.wifiResults = lines.map(line => popup.parseWifiLine(line)).filter(item => item !== null);
                popup.finishWifiScan();
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) popup.wifiScanMessage = "Wi-Fi scan failed (" + exitCode + ")";
            popup.finishWifiScan();
        }
    }

    Process {
        id: bluetoothScanProcess
        command: ["bluetoothctl"]
        stdinEnabled: true
        onStarted: write("scan on\n")
        stdout: SplitParser {
            onRead: data => popup.handleBluetoothLine(data)
        }
        onRunningChanged: if (!running && popup.bluetoothScanning) popup.finishBluetoothScan()
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
    Timer { id: wifiScanAfterEnable; interval: 1200; repeat: false; onTriggered: wifiState.running = true }
    Timer { id: wifiScanTimeout; interval: 20000; repeat: false; onTriggered: finishWifiScan() }
    Timer { id: bluetoothScanAfterEnable; interval: 1200; repeat: false; onTriggered: bluetoothState.running = true }
    Timer { id: bluetoothStopTimer; interval: 12000; repeat: false; onTriggered: finishBluetoothScan() }
    Timer { id: bluetoothProcessCleanup; interval: 350; repeat: false; onTriggered: bluetoothScanProcess.running = false }
    SequentialAnimation {
        id: opening
        NumberAnimation {
            target: panel
            property: "opacity"
            from: 0
            to: 1
            duration: 160
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: panel
            property: "offsetY"
            from: -5
            to: 0
            duration: 180
            easing.type: Easing.OutCubic
        }
    }
    SequentialAnimation {
        id: closing
        NumberAnimation {
            target: panel
            property: "opacity"
            to: 0
            duration: 110
            easing.type: Easing.InCubic
        }
        ScriptAction {
            script: popup.visible = false
        }
    }

    Rectangle {
        id: panel
        anchors.fill: parent
        radius: 17
        color: Qt.rgba(popup.backgroundColor.r, popup.backgroundColor.g, popup.backgroundColor.b, 0.98)
        border.width: 1
        border.color: Qt.rgba(popup.foregroundColor.r, popup.foregroundColor.g, popup.foregroundColor.b, 0.14)
        opacity: 0
        property real offsetY: -5
        transform: Translate { y: panel.offsetY }
        Behavior on opacity { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

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
                    MouseArea { id: closeMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { opening.stop(); closing.restart(); } }
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
                    onClicked: {
                        if (popup.wifiEnabled) popup.cancelWifiScan();
                        const turnOn = !popup.wifiEnabled;
                        popup.wifiScanMessage = "";
                        wifiCommand.exec(["nmcli", "radio", "wifi", turnOn ? "on" : "off"]);
                        if (turnOn && popup.networkDetails) {
                            popup.wifiScanPending = true;
                            popup.wifiScanning = true;
                            popup.wifiScanTimeout.restart();
                            wifiScanAfterEnable.restart();
                        }
                        refreshSoon.restart();
                    }
                }
                ControlTile {
                    Layout.fillWidth: true
                    title: "Bluetooth"; detail: popup.bluetoothName; glyph: "ᛒ"
                    enabledState: popup.bluetoothEnabled; backgroundColor: popup.backgroundColor
                    foregroundColor: popup.foregroundColor; accentColor: popup.accentColor
                    onClicked: {
                        if (popup.bluetoothEnabled) {
                            popup.finishBluetoothScan();
                        } else if (popup.bluetoothScanning || popup.bluetoothScanPending) {
                            popup.finishBluetoothScan();
                        }
                        const turnOn = !popup.bluetoothEnabled;
                        popup.bluetoothScanMessage = "";
                        bluetoothCommand.exec(["bluetoothctl", "power", turnOn ? "on" : "off"]);
                        if (turnOn && popup.bluetoothDetails) {
                            popup.bluetoothScanPending = true;
                            popup.bluetoothScanning = true;
                            bluetoothScanAfterEnable.restart();
                            popup.bluetoothStopTimer.restart();
                        }
                        refreshSoon.restart();
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Rectangle {
                    Layout.fillWidth: true; height: 27; radius: 8
                    color: networkExpand.containsMouse ? popup.secondaryColor : "transparent"
                    RowLayout {
                        anchors.centerIn: parent; spacing: 5
                        Text { visible: popup.wifiScanning; text: "◌"; color: popup.accentColor; font.pixelSize: 12; RotationAnimation on rotation { from: 0; to: 360; duration: 800; loops: Animation.Infinite; running: popup.wifiScanning } }
                        Text { text: popup.wifiScanning ? "Scanning Wi-Fi…" : (popup.networkDetails ? "Wi-Fi networks  ⌄" : "Wi-Fi networks  ›"); color: popup.foregroundColor; font.pixelSize: 10; font.bold: true }
                    }
                    MouseArea { id: networkExpand; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { popup.bluetoothDetails = false; popup.networkDetails = !popup.networkDetails; if (!popup.networkDetails) popup.cancelWifiScan(); else popup.startWifiScan(); } }
                }
                Rectangle {
                    Layout.fillWidth: true; height: 27; radius: 8
                    color: bluetoothExpand.containsMouse ? popup.secondaryColor : "transparent"
                    RowLayout {
                        anchors.centerIn: parent; spacing: 5
                        Text { visible: popup.bluetoothScanning; text: "◌"; color: popup.accentColor; font.pixelSize: 12; RotationAnimation on rotation { from: 0; to: 360; duration: 800; loops: Animation.Infinite; running: popup.bluetoothScanning } }
                        Text { text: popup.bluetoothScanning ? "Scanning Bluetooth…" : (popup.bluetoothDetails ? "Bluetooth devices  ⌄" : "Bluetooth devices  ›"); color: popup.foregroundColor; font.pixelSize: 10; font.bold: true }
                    }
                    MouseArea { id: bluetoothExpand; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { popup.networkDetails = false; popup.bluetoothDetails = !popup.bluetoothDetails; if (!popup.bluetoothDetails) popup.finishBluetoothScan(); else popup.startBluetoothScan(); } }
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
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { popup.audioTab = modelData.key; popup.deviceMenuTab = ""; if (modelData.key === "output") outputVolumeState.running = true; else inputVolumeState.running = true; } }
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
                            stepSize: 0.01
                            live: true
                            onMoved: popup.setAudioVolume(value)
                            onValueChanged: if (pressed) popup.setAudioVolume(value)
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
                        model: popup.deviceMenuTab === popup.audioTab ? (popup.audioTab === "output" ? popup.audioOutputs : popup.audioInputs).slice(0, 3) : []
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
                        model: popup.networkDetails ? popup.wifiResults.slice(0, 3) : (popup.bluetoothDetails ? popup.bluetoothList.slice(0, 3) : [])
                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true; height: 19; radius: 5
                            color: detailItemMouse.containsMouse ? popup.secondaryColor : "transparent"
                            Text {
                                anchors.left: parent.left; anchors.leftMargin: 6; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                text: popup.networkDetails
                                    ? ((modelData.active ? "✓  " : "◉  ") + modelData.ssid + (modelData.signal ? " · " + modelData.signal + "%" : ""))
                                    : ((modelData.connected ? "✓  " : "ᛒ  ") + modelData.name + (modelData.connected ? " · Connected" : ""))
                                color: popup.foregroundColor; font.pixelSize: 9; elide: Text.ElideRight
                            }
                            MouseArea {
                                id: detailItemMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (popup.networkDetails) {
                                        if (modelData.active) return;
                                        if (modelData.saved || popup.savedNetworks.indexOf(modelData.ssid) >= 0)
                                            wifiCommand.exec(["nmcli", "connection", "up", "id", modelData.ssid]);
                                        else
                                            wifiCommand.exec(["nmcli", "device", "wifi", "connect", modelData.ssid]);
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
                        visible: popup.networkDetails ? (!popup.wifiScanning && popup.wifiResults.length === 0 && popup.savedNetworks.length === 0) : (!popup.bluetoothScanning && popup.bluetoothList.length === 0)
                        text: popup.networkDetails ? (popup.wifiScanMessage || (popup.wifiScanning ? "Searching nearby networks…" : "No networks found")) : (popup.bluetoothScanMessage || (popup.bluetoothScanning ? "Searching for nearby devices…" : "No paired or nearby devices"))
                        color: Qt.rgba(popup.foregroundColor.r, popup.foregroundColor.g, popup.foregroundColor.b, 0.52); font.pixelSize: 9
                    }
                }
            }
        }
    }
}
