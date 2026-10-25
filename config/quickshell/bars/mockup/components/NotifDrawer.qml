import QtQuick
import "." as MockupComponents
import QtQuick.Layouts

Rectangle {
    id: drawer
    property bool open: false
    property color bg: MockupComponents.Palette.bg
    property color fg: MockupComponents.Palette.fg
    property color dark: MockupComponents.Palette.dark
    property color accent: MockupComponents.Palette.accent
    property color secondary: MockupComponents.Palette.secondary
    property string uiFont: "Inter"
    property var notifications: []
    property bool dnd: false
    signal closed()
    signal clearRequested()
    signal dndToggled(bool enabled)

    color: Qt.rgba(bg.r, bg.g, bg.b, 0.95)
    border.width: 0
    x: open ? 0 : width
    Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    Rectangle {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: 1
        color: Qt.rgba(drawer.accent.r, drawer.accent.g, drawer.accent.b, 0.3)
    }

    Rectangle {
        id: head
        width: parent.width
        height: 56
        color: Qt.rgba(drawer.dark.r, drawer.dark.g, drawer.dark.b, 0.8)
        Icon {
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            name: "bell"
            tone: "accent"
            size: 16
        }
        Text {
            anchors.left: parent.left
            anchors.leftMargin: 40
            anchors.verticalCenter: parent.verticalCenter
            text: "Notifications"
            color: drawer.fg
            font.bold: true
            font.pixelSize: 13
            font.family: drawer.uiFont
        }
        Icon {
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            name: "x"
            tone: "fg"
            size: 16
            MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; onClicked: drawer.closed() }
        }
    }

    Rectangle {
        id: toolbar
        anchors.top: head.bottom
        width: parent.width
        height: 40
        color: Qt.rgba(drawer.dark.r, drawer.dark.g, drawer.dark.b, 0.4)
        Row {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            Icon {
                name: "moon"
                tone: dndMouse.containsMouse ? "accent" : "fg"
                size: 14
            }
            Text {
                text: "Do Not Disturb"
                color: dndMouse.containsMouse ? drawer.accent : drawer.fg
                font.pixelSize: 11
                font.family: drawer.uiFont
            }
            Text {
                text: drawer.dnd ? "On" : "Off"
                color: drawer.dnd ? drawer.accent : Qt.rgba(drawer.fg.r, drawer.fg.g, drawer.fg.b, 0.55)
                font.pixelSize: 10
                font.family: drawer.uiFont
            }
        }
        MouseArea {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 170
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            id: dndMouse
            onClicked: drawer.dndToggled(!drawer.dnd)
        }
        Text {
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: "Clear All"
            color: clearMouse.containsMouse ? MockupComponents.Palette.error : drawer.fg
            font.pixelSize: 11
            font.family: drawer.uiFont
            MouseArea {
                id: clearMouse
                anchors.fill: parent
                anchors.margins: -8
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: drawer.clearRequested()
            }
        }
    }

    ListView {
        id: notificationList
        anchors.top: toolbar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 12
        spacing: 12
        clip: true
        model: drawer.notifications
        delegate: Rectangle {
            required property var modelData
            width: notificationList.width
            height: Math.max(76, cardBody.implicitHeight + 30)
            radius: 12
            color: Qt.rgba(drawer.secondary.r, drawer.secondary.g, drawer.secondary.b, 0.2)
            border.width: 1
            border.color: cardHover.containsMouse ? drawer.accent
                : Qt.rgba(drawer.accent.r, drawer.accent.g, drawer.accent.b, 0.3)
            Behavior on border.color { ColorAnimation { duration: 120 } }
            HoverHandler { id: cardHover }
            Row {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.top: parent.top
                anchors.topMargin: 12
                spacing: 8
                Icon {
                    name: "message-square"
                    tone: "sky"
                    size: 14
                    visible: /discord|message|chat/i.test(modelData.appName || modelData.desktopEntry || "")
                }
                Icon {
                    name: "download"
                    tone: "accent"
                    size: 14
                    visible: !/discord|message|chat/i.test(modelData.appName || modelData.desktopEntry || "")
                }
                Text {
                    text: modelData.summary || modelData.appName || modelData.desktopEntry || "Notification"
                    color: /discord|message|chat/i.test(modelData.appName || modelData.desktopEntry || "")
                        ? MockupComponents.Palette.cyan : drawer.accent
                    font.bold: true
                    font.pixelSize: 12
                    font.family: drawer.uiFont
                    elide: Text.ElideRight
                    width: notificationList.width - 70
                }
            }
            Icon {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: 8
                anchors.rightMargin: 8
                name: "x"
                tone: "muted"
                size: 14
                MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: modelData.dismiss() }
            }
            Column {
                id: cardBody
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 34
                anchors.rightMargin: 12
                anchors.top: parent.top
                anchors.topMargin: 34
                spacing: 3
                Text {
                    width: parent.width
                    text: modelData.summary || ""
                    color: Qt.rgba(drawer.fg.r, drawer.fg.g, drawer.fg.b, 0.8)
                    font.pixelSize: 11
                    font.family: drawer.uiFont
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: modelData.body || ""
                    color: Qt.rgba(drawer.fg.r, drawer.fg.g, drawer.fg.b, 0.8)
                    font.pixelSize: 11
                    font.family: drawer.uiFont
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }
                Repeater {
                    model: modelData.actions || []
                    delegate: Rectangle {
                        required property var modelData
                        width: actionLabel.implicitWidth + 16
                        height: 22
                        radius: 5
                        color: Qt.rgba(drawer.dark.r, drawer.dark.g, drawer.dark.b, 0.65)
                        Text {
                            id: actionLabel
                            anchors.centerIn: parent
                            text: modelData.text
                            color: drawer.fg
                            font.pixelSize: 10
                            font.family: drawer.uiFont
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: modelData.invoke()
                        }
                    }
                }
            }
        }
        Text {
            anchors.centerIn: parent
            visible: drawer.notifications.length === 0
            text: "No notifications"
            color: Qt.rgba(drawer.fg.r, drawer.fg.g, drawer.fg.b, 0.5)
            font.pixelSize: 12
            font.family: drawer.uiFont
        }
    }
}
