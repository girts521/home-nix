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

    // Position: item-relative rect. Centered under the chip, clamped inside the bar.
    anchor.item: anchorItem
    anchor.rect.x: {
        if (!anchorItem) return 0;
        const origin = anchorItem.mapToItem(null, 0, 0);
        const want = origin.x + anchorItem.width / 2 - panelWidth / 2;
        const clamped = Math.max(6, Math.min(barWidth - panelWidth - 6, want));
        return clamped - origin.x;
    }
    anchor.rect.y: anchorItem ? anchorItem.height + 6 : 0

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
