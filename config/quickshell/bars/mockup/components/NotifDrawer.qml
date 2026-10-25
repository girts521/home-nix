import QtQuick
import QtQuick.Layouts

// Right-side notifications drawer, matching the mockup's #notif-sidebar.
// Slides in from the right edge of the bar's screen.
Rectangle {
    id: drawer
    property bool open: false
    property color bg: "#122957"
    property color fg: "#c6cff5"
    property color accent: "#8e81d9"
    property color secondary: "#3f5ac8"

    signal closed()

    color: Qt.rgba(bg.r, bg.g, bg.b, 0.95)
    border.width: 1
    border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.3)
    x: open ? 0 : width
    Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    // Header
    Rectangle {
        id: head
        width: parent.width; height: 48
        color: Qt.rgba(0.04, 0.08, 0.2, 0.8)
        Text { anchors.left: parent.left; anchors.leftMargin: 16; anchors.verticalCenter: parent.verticalCenter; text: "🔔  Notifications"; color: drawer.fg; font.bold: true; font.pixelSize: 13 }
        Text {
            anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter
            text: "✕"; color: drawer.fg; font.pixelSize: 13
            MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; onClicked: drawer.closed() }
        }
    }

    // Toolbar
    Rectangle {
        id: bar2
        anchors.top: head.bottom
        width: parent.width; height: 36
        color: Qt.rgba(0.04, 0.08, 0.2, 0.5)
        Text { anchors.left: parent.left; anchors.leftMargin: 16; anchors.verticalCenter: parent.verticalCenter; text: "☾ Do Not Disturb"; color: drawer.fg; font.pixelSize: 11 }
        Text { anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter; text: "Clear All"; color: drawer.fg; font.pixelSize: 11 }
    }

    // Cards (static sample data, same as the HTML)
    Column {
        anchors.top: bar2.bottom
        anchors.left: parent.left; anchors.right: parent.right
        anchors.margins: 12
        spacing: 10

        Repeater {
            model: [
                { app: "Update Ready", msg: "Arch Linux kernel upgrade available.", when: "2 mins ago", col: drawer.accent },
                { app: "Discord", msg: "New message in #ricing-community.", when: "15 mins ago", col: "#38bdf8" }
            ]
            Rectangle {
                required property var modelData
                width: parent.width
                height: 76
                radius: 12
                color: Qt.rgba(drawer.secondary.r, drawer.secondary.g, drawer.secondary.b, 0.2)
                border.width: 1
                border.color: Qt.rgba(drawer.accent.r, drawer.accent.g, drawer.accent.b, 0.3)
                Column {
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.margins: 12; anchors.top: parent.top; anchors.topMargin: 10
                    spacing: 4
                    Text { text: modelData.app; color: modelData.col; font.bold: true; font.pixelSize: 12 }
                    Text { text: modelData.msg; color: Qt.rgba(drawer.fg.r, drawer.fg.g, drawer.fg.b, 0.8); font.pixelSize: 11 }
                    Text { text: modelData.when; color: Qt.rgba(drawer.fg.r, drawer.fg.g, drawer.fg.b, 0.5); font.pixelSize: 9 }
                }
            }
        }
    }
}
