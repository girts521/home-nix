import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications

// Notification drawer backed by notifications received by this Quickshell instance.
Rectangle {
    id: drawer
    property bool open: false
    property color bg: "#122957"
    property color fg: "#c6cff5"
    property color accent: "#8e81d9"
    property color secondary: "#3f5ac8"
    property var notifications: []
    property bool dnd: false

    signal closed()
    signal clearRequested()
    signal dndToggled(bool enabled)

    color: Qt.rgba(bg.r, bg.g, bg.b, 0.95)
    border.width: 1
    border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.3)
    x: open ? 0 : width
    Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    Rectangle {
        id: head
        width: parent.width; height: 48
        color: Qt.rgba(0.04, 0.08, 0.2, 0.8)
        Text {
            anchors.left: parent.left; anchors.leftMargin: 16; anchors.verticalCenter: parent.verticalCenter
            text: "🔔  Notifications"; color: drawer.fg; font.bold: true; font.pixelSize: 13
        }
        Text {
            anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter
            text: "✕"; color: drawer.fg; font.pixelSize: 13
            MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; onClicked: drawer.closed() }
        }
    }

    Rectangle {
        id: toolbar
        anchors.top: head.bottom
        width: parent.width; height: 36
        color: Qt.rgba(0.04, 0.08, 0.2, 0.5)
        Text {
            anchors.left: parent.left; anchors.leftMargin: 16; anchors.verticalCenter: parent.verticalCenter
            text: "☾ Do Not Disturb"; color: drawer.fg; font.pixelSize: 11
        }
        MouseArea {
            anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; width: 160
            cursorShape: Qt.PointingHandCursor
            onClicked: drawer.dndToggled(!drawer.dnd)
        }
        Text {
            anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter
            text: "Clear All"; color: drawer.fg; font.pixelSize: 11
        }
        MouseArea {
            anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom; width: 84
            cursorShape: Qt.PointingHandCursor
            onClicked: drawer.clearRequested()
        }
    }

    ListView {
        id: notificationList
        anchors.top: toolbar.bottom
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        anchors.margins: 12
        spacing: 10
        clip: true
        model: drawer.notifications
        delegate: Rectangle {
            required property var modelData
            width: notificationList.width
            height: Math.max(82, cardBody.implicitHeight + 22)
            radius: 12
            color: Qt.rgba(drawer.secondary.r, drawer.secondary.g, drawer.secondary.b, 0.2)
            border.width: 1
            border.color: Qt.rgba(drawer.accent.r, drawer.accent.g, drawer.accent.b, 0.3)

            Column {
                id: cardBody
                anchors.left: parent.left; anchors.right: parent.right
                anchors.margins: 12; anchors.top: parent.top; anchors.topMargin: 10
                spacing: 4
                Text {
                    width: parent.width
                    text: modelData.appName || modelData.desktopEntry || "Notification"
                    color: drawer.accent; font.bold: true; font.pixelSize: 12
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: modelData.summary || ""
                    color: drawer.fg; font.bold: true; font.pixelSize: 11
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: modelData.body || ""
                    color: Qt.rgba(drawer.fg.r, drawer.fg.g, drawer.fg.b, 0.8); font.pixelSize: 11
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }
            }
            Text {
                anchors.top: parent.top; anchors.right: parent.right
                anchors.topMargin: 6; anchors.rightMargin: 8
                text: "×"; color: Qt.rgba(drawer.fg.r, drawer.fg.g, drawer.fg.b, 0.65); font.pixelSize: 14
                MouseArea {
                    anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor
                    onClicked: modelData.dismiss()
                }
            }
        }
        Text {
            anchors.centerIn: parent
            visible: drawer.notifications.length === 0
            text: "No notifications"
            color: Qt.rgba(drawer.fg.r, drawer.fg.g, drawer.fg.b, 0.5); font.pixelSize: 12
        }
    }
}
