import Quickshell
import Quickshell.Wayland
import QtQuick
import "." as MockupComponents

// Shared popup frame and HTML-style anchor placement. Individual panels retain
// the reference's own padding, radius, height, and internal arrangement.
PopupWindow {
    id: pop
    property Item anchorItem
    property bool open: false
    property real panelWidth: 320
    property int contentInset: 16
    property int contentSpacing: 12
    property int cornerRadius: 12
    // Chips sit 10px inside the 50px bar surface; 12px places the popup
    // two pixels below the bar's bottom edge rather than overlapping it.
    property int dropGap: 12
    property color bg: MockupComponents.Palette.bg
    property color fg: MockupComponents.Palette.fg
    property color dark: MockupComponents.Palette.dark
    property color accent: MockupComponents.Palette.accent
    property color secondary: MockupComponents.Palette.secondary
    property color green: MockupComponents.Palette.green
    property color blue: MockupComponents.Palette.cyan
    property color warning: MockupComponents.Palette.warning
    property color muted: MockupComponents.Palette.muted
    property color bright: MockupComponents.Palette.bright
    property color error: MockupComponents.Palette.error
    property color subtle: MockupComponents.Palette.subtle
    property string uiFont: "Inter"
    signal dismissed()
    default property alias content: body.data

    readonly property real barWidth: anchor.window ? anchor.window.width : 0
    implicitWidth: panelWidth
    implicitHeight: body.implicitHeight + contentInset * 2
    color: "transparent"
    // Quickshell hides the popup on outside-click; the handler then clears the
    // owning open state so this visibility binding stays false. Keep the grab
    // enabled as a constant: Quickshell only applies grabFocus changes after a
    // popup is hidden/shown, so toggling it alongside visible can miss a grab.
    visible: open
    grabFocus: true
    onVisibleChanged: if (!visible && open) pop.dismissed()

    BackgroundEffect.blurRegion: Region { item: frame }

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
        return origin.y + anchorItem.height + dropGap;
    }

    Rectangle {
        id: frame
        anchors.fill: parent
        radius: pop.cornerRadius
        color: Qt.rgba(pop.bg.r, pop.bg.g, pop.bg.b, 0.82)
        border.width: 1
        border.color: Qt.rgba(pop.accent.r, pop.accent.g, pop.accent.b, 0.4)
        opacity: pop.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Column {
            id: body
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: pop.contentInset
            spacing: pop.contentSpacing
        }
    }
}
