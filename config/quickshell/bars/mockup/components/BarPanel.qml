import Quickshell
import QtQuick

// Shared floating panel for every popup in the mockup bar.
// Centers horizontally under its anchor item, clamps to the screen edges,
// fades in/out, and reports dismissal (click outside) back to the bar.
PopupWindow {
    id: pop

    property var barWindow
    property Item anchorItem
    property bool open: false
    property real panelWidth: 320

    property color bg: "#122957"
    property color fg: "#c6cff5"
    property color accent: "#8e81d9"
    property color secondary: "#3f5ac8"

    // Emitted when the compositor dismisses the popup (e.g. click outside).
    signal dismissed()

    default property alias content: body.data

    implicitWidth: panelWidth
    implicitHeight: body.height + 32
    color: "transparent"
    visible: open || frame.opacity > 0.01
    grabFocus: open

    anchor.window: barWindow
    anchor.rect.x: {
        if (!anchorItem || !barWindow) return 0;
        const p = anchorItem.mapToItem(null, 0, 0);
        const x = Math.round(p.x + anchorItem.width / 2 - pop.implicitWidth / 2);
        return Math.max(6, Math.min(barWindow.width - pop.implicitWidth - 6, x));
    }
    anchor.rect.y: barWindow ? barWindow.height + 4 : 0

    onVisibleChanged: {
        if (!visible && open) pop.dismissed();
    }

    Rectangle {
        id: frame
        anchors.fill: parent
        radius: 12
        color: Qt.rgba(pop.bg.r, pop.bg.g, pop.bg.b, 0.95)
        border.width: 1
        border.color: Qt.rgba(pop.accent.r, pop.accent.g, pop.accent.b, 0.4)
        opacity: pop.open ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }

        Column {
            id: body
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 16
            spacing: 12
        }
    }
}
