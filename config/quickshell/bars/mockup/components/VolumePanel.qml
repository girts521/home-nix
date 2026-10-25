import Quickshell
import QtQuick
import QtQuick.Controls

BarPanel {
    id: panel
    required property var sys

    bg: sys.bg
    fg: sys.fg
    dark: sys.dark
    accent: sys.accent
    secondary: sys.secondary
    panelWidth: 320
    contentInset: 16
    contentSpacing: 12
    cornerRadius: 12

    readonly property string outputId: {
        const d = sys.audioOutputs.find(x => x.active);
        return d ? d.id : "@DEFAULT_AUDIO_SINK@";
    }
    readonly property string inputId: {
        const d = sys.audioInputs.find(x => x.active);
        return d ? d.id : "@DEFAULT_AUDIO_SOURCE@";
    }
    // Do not capture microphone audio for a live meter without explicit opt-in.
    // The former random animation was not a real microphone signal.

    function setDefaultDevice(deviceId) {
        if (deviceId !== undefined && deviceId !== "")
            Quickshell.execDetached(["wpctl", "set-default", String(deviceId)]);
    }
    function setVolume(deviceId, value) {
        Quickshell.execDetached(["wpctl", "set-volume", deviceId, Math.max(0, Math.min(1, value)).toFixed(2)]);
    }
    function toggleMute(deviceId) {
        Quickshell.execDetached(["wpctl", "set-mute", deviceId, "toggle"]);
    }

    Item {
        width: parent.width
        height: 28
        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            Icon { name: "volume-2"; tone: "accent"; size: 16 }
            Text { text: "Sound"; color: panel.fg; font.bold: true; font.pixelSize: 13; font.family: panel.uiFont; anchors.verticalCenter: parent.verticalCenter }
        }
        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: muteLabel.implicitWidth + 26
            height: 24
            radius: 5
            color: muteMouse.containsMouse ? Qt.rgba(panel.secondary.r, panel.secondary.g, panel.secondary.b, 0.3) : "transparent"
            Row {
                anchors.centerIn: parent
                spacing: 4
                Icon { name: "volume-x"; tone: "accent"; size: 12; anchors.verticalCenter: parent.verticalCenter }
                Text { id: muteLabel; text: panel.sys.outMuted ? "Unmute" : "Mute"; color: panel.fg; font.pixelSize: 11; font.family: panel.uiFont; anchors.verticalCenter: parent.verticalCenter }
            }
            MouseArea { id: muteMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panel.toggleMute(panel.outputId) }
        }
    }

    Rectangle { width: parent.width; height: 1; color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.1) }

    Column {
        width: parent.width
        spacing: 6

        Item {
            width: parent.width
            height: 14
            Text { anchors.left: parent.left; text: "OUTPUT"; color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.5); font.pixelSize: 10; font.bold: true; font.family: panel.uiFont }
            Text { anchors.right: parent.right; text: Math.round(Math.min(1, panel.sys.outVolume) * 100) + "%"; color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.5); font.pixelSize: 10; font.family: "monospace" }
        }
        ComboBox {
            id: outputSelect
            width: parent.width
            height: 30
            model: panel.sys.audioOutputs
            textRole: "name"
            currentIndex: {
                const i = panel.sys.audioOutputs.findIndex(x => x.active);
                return i >= 0 ? i : 0;
            }
            displayText: panel.sys.audioOutputs.length > 0 ? currentText : "No output devices found"
            onActivated: index => {
                const deviceId = panel.sys.audioOutputs[index].id;
                panel.setDefaultDevice(deviceId);
                Qt.callLater(panel.sys.refreshDevices);
            }
            font.family: panel.uiFont
            font.pixelSize: 12
            contentItem: Text {
                leftPadding: 8
                rightPadding: 24
                text: outputSelect.displayText
                color: panel.fg
                font: outputSelect.font
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
            indicator: Text { x: outputSelect.width - width - 10; y: (outputSelect.height - height) / 2; text: "⌄"; color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.6); font.pixelSize: 16; font.family: panel.uiFont }
            background: Rectangle { color: panel.dark; radius: 6; border.width: 1; border.color: Qt.rgba(panel.accent.r, panel.accent.g, panel.accent.b, 0.4) }
            popup.width: outputSelect.width
            popup.contentItem: ListView {
                implicitHeight: Math.min(contentHeight, 180)
                model: outputSelect.popup.visible ? outputSelect.delegateModel : null
                clip: true
                currentIndex: outputSelect.highlightedIndex
            }
            delegate: ItemDelegate {
                width: outputSelect.width
                height: 30
                text: modelData.name
                highlighted: outputSelect.highlightedIndex === index
                contentItem: Text { text: parent.text; color: panel.fg; font: outputSelect.font; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight; leftPadding: 8 }
                background: Rectangle { color: parent.highlighted ? Qt.rgba(panel.accent.r, panel.accent.g, panel.accent.b, 0.25) : panel.bg }
            }
        }
        Row {
            width: parent.width
            height: 32
            spacing: 8
            Icon { name: "speaker"; tone: "muted"; size: 14; anchors.verticalCenter: parent.verticalCenter }
            Slider {
                id: outputSlider
                width: parent.width - 22
                height: 30
                anchors.verticalCenter: parent.verticalCenter
                from: 0
                to: 1
                value: Math.min(1, panel.sys.outVolume)
                onMoved: panel.setVolume(panel.outputId, value)
                background: Rectangle {
                    x: outputSlider.leftPadding
                    y: outputSlider.topPadding + outputSlider.availableHeight / 2 - height / 2
                    width: outputSlider.availableWidth
                    height: 4
                    radius: 2
                    color: panel.dark
                    Rectangle { width: parent.width * outputSlider.visualPosition; height: parent.height; radius: 2; color: panel.accent }
                }
                handle: Rectangle { x: outputSlider.leftPadding + outputSlider.visualPosition * (outputSlider.availableWidth - width); y: outputSlider.topPadding + outputSlider.availableHeight / 2 - height / 2; width: 14; height: 14; radius: 7; color: panel.accent; border.width: 2; border.color: panel.fg }
            }
        }
        Text {
            width: parent.width
            text: "Now: " + (panel.sys.audioOutputs.find(x => x.active)?.name || "No output device")
            color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.5)
            font.pixelSize: 10
            font.family: "monospace"
            elide: Text.ElideRight
        }
    }

    Rectangle { width: parent.width; height: 1; color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.1) }

    Column {
        width: parent.width
        spacing: 6
        Item {
            width: parent.width
            height: 14
            Text { anchors.left: parent.left; text: "INPUT"; color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.5); font.pixelSize: 10; font.bold: true; font.family: panel.uiFont }
            Text { anchors.right: parent.right; text: Math.round(Math.min(1, panel.sys.inVolume) * 100) + "%"; color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.5); font.pixelSize: 10; font.family: "monospace" }
        }
        ComboBox {
            id: inputSelect
            width: parent.width
            height: 30
            model: panel.sys.audioInputs
            textRole: "name"
            currentIndex: {
                const i = panel.sys.audioInputs.findIndex(x => x.active);
                return i >= 0 ? i : 0;
            }
            displayText: panel.sys.audioInputs.length > 0 ? currentText : "No input devices found"
            onActivated: index => {
                const deviceId = panel.sys.audioInputs[index].id;
                panel.setDefaultDevice(deviceId);
                Qt.callLater(panel.sys.refreshDevices);
            }
            font.family: panel.uiFont
            font.pixelSize: 12
            contentItem: Text {
                leftPadding: 8
                rightPadding: 24
                text: inputSelect.displayText
                color: panel.fg
                font: inputSelect.font
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
            indicator: Text { x: inputSelect.width - width - 10; y: (inputSelect.height - height) / 2; text: "⌄"; color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.6); font.pixelSize: 16; font.family: panel.uiFont }
            background: Rectangle { color: panel.dark; radius: 6; border.width: 1; border.color: Qt.rgba(panel.accent.r, panel.accent.g, panel.accent.b, 0.4) }
            popup.width: inputSelect.width
            popup.contentItem: ListView {
                implicitHeight: Math.min(contentHeight, 180)
                model: inputSelect.popup.visible ? inputSelect.delegateModel : null
                clip: true
                currentIndex: inputSelect.highlightedIndex
            }
            delegate: ItemDelegate {
                width: inputSelect.width
                height: 30
                text: modelData.name
                highlighted: inputSelect.highlightedIndex === index
                contentItem: Text { text: parent.text; color: panel.fg; font: inputSelect.font; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight; leftPadding: 8 }
                background: Rectangle { color: parent.highlighted ? Qt.rgba(panel.accent.r, panel.accent.g, panel.accent.b, 0.25) : panel.bg }
            }
        }
        Row {
            width: parent.width
            height: 30
            spacing: 8
            Icon { name: "mic"; tone: "muted"; size: 14; anchors.verticalCenter: parent.verticalCenter }
            Slider {
                id: inputSlider
                width: parent.width - 22
                anchors.verticalCenter: parent.verticalCenter
                from: 0
                to: 1
                value: Math.min(1, panel.sys.inVolume)
                onMoved: panel.setVolume(panel.inputId, value)
                background: Rectangle {
                    x: inputSlider.leftPadding
                    y: inputSlider.topPadding + inputSlider.availableHeight / 2 - height / 2
                    width: inputSlider.availableWidth
                    height: 4
                    radius: 2
                    color: panel.dark
                    Rectangle { width: parent.width * inputSlider.visualPosition; height: parent.height; radius: 2; color: panel.accent }
                }
                handle: Rectangle { x: inputSlider.leftPadding + inputSlider.visualPosition * (inputSlider.availableWidth - width); y: inputSlider.topPadding + inputSlider.availableHeight / 2 - height / 2; width: 14; height: 14; radius: 7; color: panel.accent; border.width: 2; border.color: panel.fg }
            }
        }
        Text {
            width: parent.width
            height: 14
            text: "Live microphone meter disabled (was random)"
            color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.42)
            font.pixelSize: 9
            font.family: panel.uiFont
        }
    }
}
