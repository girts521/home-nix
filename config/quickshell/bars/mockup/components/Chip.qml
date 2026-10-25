import QtQuick
import "." as MockupComponents

Rectangle {
    id: chip
    property string glyph: ""
    property string label: ""
    property color textColor: MockupComponents.Palette.fg
    property color iconColor: MockupComponents.Palette.accent
    property color mutedColor: MockupComponents.Palette.muted
    property color brightColor: MockupComponents.Palette.bright
    property color fillColor: "transparent"
    property color hoverColor: MockupComponents.Palette.secondary
    property color borderColor: "transparent"
    property int iconSize: 14
    property int horizontalPadding: 8
    property int gap: 6
    property bool highlighted: false
    property bool iconOnly: false
    property bool mono: true
    property bool bold: false
    property string iconTone: "accent"
    property string uiFont: "Inter"

    signal clicked()

    height: 30
    width: iconOnly ? 28 : row.implicitWidth + horizontalPadding * 2
    radius: 6
    color: ma.containsMouse || highlighted ? hoverColor : fillColor
    border.width: borderColor.a === 0 ? 0 : 1
    border.color: borderColor
    Behavior on color { ColorAnimation { duration: 150 } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: chip.gap
        Icon {
            visible: chip.glyph !== ""
            anchors.verticalCenter: parent.verticalCenter
            name: chip.glyph
            tone: chip.iconTone
            tint: chip.iconColor
            size: chip.iconSize
        }
        Text {
            visible: !chip.iconOnly
            anchors.verticalCenter: parent.verticalCenter
            text: chip.label
            color: chip.textColor
            font.pixelSize: 12
            font.family: chip.mono ? "monospace" : chip.uiFont
            font.bold: chip.bold
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
