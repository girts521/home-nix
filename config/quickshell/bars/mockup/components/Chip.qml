import QtQuick

// Clickable pill used for the bar's status chips (CPU, RAM, disk, volume...).
Rectangle {
    id: chip

    property string glyph: ""
    property string label: ""
    property color textColor: "#c6cff5"
    property color iconColor: "#8e81d9"
    property color fillColor: "#3f5ac8"
    property color hoverColor: "#8e81d9"
    property color borderColor: "#8e81d9"
    property bool highlighted: false

    signal clicked()

    height: 30
    width: row.implicitWidth + 16
    radius: 6
    color: ma.containsMouse || highlighted ? hoverColor : fillColor
    border.width: 1
    border.color: borderColor

    Behavior on color { ColorAnimation { duration: 150 } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Text {
            visible: chip.glyph !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: chip.glyph
            color: chip.iconColor
            font.pixelSize: 13
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: chip.label
            color: chip.textColor
            font.pixelSize: 12
            font.family: "monospace"
            font.bold: true
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: chip.clicked()
    }
}
