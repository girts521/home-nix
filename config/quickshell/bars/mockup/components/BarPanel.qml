import Quickshell
import QtQuick

// Shared floating panel for every popup in the mockup bar.
// Positioned relative to the chip that opened it (anchorItem), centered under
// that chip, and clamped to the bar window's horizontal extent.
PopupWindow {
    id: pop

    property Item anchorItem
    property bool open: false
    property real panelWidth: 320

    property color bg: "#122957"
    property color fg: "#c6cff5"
    property color accent: "#8e81d9"
    property color secondary: "#3f5ac8"

    // Emitted when the popup closes because the user clicked outside it.
    signal dismissed()

    default property alias content: body.data

    readonly property real barWidth: anchor.window ? anchor.window.width : 0

    implicitWidth: panelWidth
    implicitHeight: body.implicitHeight + 32
    color: "transparent"
    visible: open || frame.opacity > 0.01
    grabFocus: open

    // Position in the parent bar window's content coordinates. Do not use
    // anchor.item here: the caller supplies anchor.window and item anchoring
    // clears it, which used to make barWidth zero and pin every popup to x=6.
    anchor.rect.x: {
        if (!anchorItem || !anchor.window) return 0;
        const origin = anchorItem.mapToItem(anchor.window.contentItem, 0, 0);
        const want = origin.x + anchorItem.width / 2 - panelWidth / 2;
        const maxX = Math.max(6, barWidth - panelWidth - 6);
        return Math.max(6, Math.min(maxX, want));
    }
    anchor.rect.y: {
        if (!anchorItem || !anchor.window) return 0;
        const origin = anchorItem.mapToItem(anchor.window.contentItem, 0, 0);
        return origin.y + anchorItem.height + 6;
    }

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
