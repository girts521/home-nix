import QtQuick
import "." as MockupComponents

// Pill switch matching the mockup's .switch element.
Rectangle {
    id: t
    property bool on: false
    property color accent: MockupComponents.Palette.accent
    property color fg: MockupComponents.Palette.fg
    signal toggled(bool state)

    width: 28; height: 16; radius: 8
    color: on ? accent : Qt.rgba(fg.r, fg.g, fg.b, 0.15)
    Behavior on color { ColorAnimation { duration: 200 } }

    Rectangle {
        width: 12; height: 12; radius: 6
        anchors.verticalCenter: parent.verticalCenter
        x: t.on ? parent.width - width - 2 : 2
        color: fg
        Behavior on x { NumberAnimation { duration: 200 } }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: { t.on = !t.on; t.toggled(t.on); }
    }
}
