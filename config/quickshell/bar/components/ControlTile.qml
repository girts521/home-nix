import QtQuick
import QtQuick.Layouts

Rectangle {
    id: tile

    signal clicked()

    property string title: ""
    property string detail: ""
    property string glyph: ""
    property bool enabledState: false
    property color foregroundColor: "#ffffff"
    property color backgroundColor: "#122957"
    property color accentColor: "#aa98f4"

    implicitHeight: 86
    radius: 13
    color: enabledState
        ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.94)
        : Qt.rgba(foregroundColor.r, foregroundColor.g, foregroundColor.b, 0.075)
    border.width: 1
    border.color: enabledState
        ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.6)
        : Qt.rgba(foregroundColor.r, foregroundColor.g, foregroundColor.b, 0.08)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 11
        spacing: 4

        Text {
            text: tile.glyph
            color: tile.enabledState ? tile.backgroundColor : tile.accentColor
            font.pixelSize: 17
        }
        Text {
            Layout.fillWidth: true
            text: tile.title
            color: tile.enabledState ? tile.backgroundColor : tile.foregroundColor
            font.pixelSize: 12
            font.bold: true
        }
        Text {
            Layout.fillWidth: true
            text: tile.detail
            color: tile.enabledState
                ? Qt.rgba(tile.backgroundColor.r, tile.backgroundColor.g, tile.backgroundColor.b, 0.78)
                : Qt.rgba(tile.foregroundColor.r, tile.foregroundColor.g, tile.foregroundColor.b, 0.62)
            font.pixelSize: 9
            elide: Text.ElideRight
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: tile.clicked()
    }
}
