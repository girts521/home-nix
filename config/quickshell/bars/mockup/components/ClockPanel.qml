import QtQuick

BarPanel {
    id: panel
    required property var now

    bg: panel.bgColor; fg: panel.fgColor; accent: panel.accentColor; secondary: panel.secondaryColor
    panelWidth: 320

    property color bgColor: "#122957"
    property color fgColor: "#c6cff5"
    property color accentColor: "#8e81d9"
    property color secondaryColor: "#3f5ac8"

    property int viewYear: now.getFullYear()
    property int viewMonth: now.getMonth()

    readonly property var monthNames: ["January","February","March","April","May","June","July","August","September","October","November","December"]

    function daysIn(y, m) { return new Date(y, m + 1, 0).getDate(); }
    // Monday-first offset
    function leadIn(y, m) { return (new Date(y, m, 1).getDay() + 6) % 7; }

    Item {
        width: parent.width
        height: 34
        Column {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            Text { text: panel.monthNames[panel.viewMonth] + " " + panel.viewYear; color: panel.accent; font.bold: true; font.pixelSize: 14 }
            Text { text: "Berlin, Germany (CET)"; color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.6); font.pixelSize: 10 }
        }
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            Repeater {
                model: [-1, 1]
                Rectangle {
                    required property var modelData
                    width: 24; height: 24; radius: 4
                    color: navMa.containsMouse ? Qt.rgba(panel.accent.r, panel.accent.g, panel.accent.b, 0.3) : "transparent"
                    Text { anchors.centerIn: parent; text: modelData < 0 ? "‹" : "›"; color: panel.fg; font.pixelSize: 16 }
                    MouseArea {
                        id: navMa
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            let m = panel.viewMonth + modelData;
                            let y = panel.viewYear;
                            if (m < 0) { m = 11; y -= 1; }
                            if (m > 11) { m = 0; y += 1; }
                            panel.viewMonth = m; panel.viewYear = y;
                        }
                    }
                }
            }
        }
    }

    Grid {
        width: parent.width
        columns: 7
        spacing: 2
        Repeater {
            model: ["Mo","Tu","We","Th","Fr","Sa","Su"]
            Text {
                required property var modelData
                width: (parent.width - 12) / 7
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.4)
                font.pixelSize: 10; font.family: "monospace"
            }
        }
        Repeater {
            model: 42
            Rectangle {
                required property int index
                readonly property int day: index - panel.leadIn(panel.viewYear, panel.viewMonth) + 1
                readonly property bool inMonth: day >= 1 && day <= panel.daysIn(panel.viewYear, panel.viewMonth)
                readonly property bool isToday: inMonth && day === panel.now.getDate()
                                                  && panel.viewMonth === panel.now.getMonth()
                                                  && panel.viewYear === panel.now.getFullYear()
                width: (panel.width - 12) / 7
                height: 26
                radius: 4
                color: isToday ? panel.accent : (dayMa.containsMouse && inMonth ? Qt.rgba(panel.accent.r, panel.accent.g, panel.accent.b, 0.25) : "transparent")
                Text {
                    anchors.centerIn: parent
                    text: inMonth ? day : ""
                    color: isToday ? "#ffffff" : (inMonth ? panel.fg : "transparent")
                    font.pixelSize: 11; font.family: "monospace"; font.bold: isToday
                }
                MouseArea { id: dayMa; anchors.fill: parent; hoverEnabled: true }
            }
        }
    }
}
