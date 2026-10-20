import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Standalone calendar UI: data comes from the independent qs-calendar-events CLI.
// Owns no Google credentials or synchronization process.
PopupWindow {
    id: popup

    property color backgroundColor: "#122957"
    property color foregroundColor: "#c6cff5"
    property color accentColor: "#8e81d9"
    property color secondaryColor: "#3f5ac8"

    property int viewYear: new Date().getFullYear()
    property int viewMonth: new Date().getMonth() // 0-11
    property date selectedDate: new Date()
    // Bound to the bar's existing SystemClock, so the Today marker updates.
    property date currentDateTime: new Date()
    readonly property string todayKey: dayKey(currentDateTime)
    property double lastScrollMs: 0
    property var events: []
    property string status: "unconfigured"
    property string statusMessage: ""

    readonly property string selectedKey: dayKey(selectedDate)
    readonly property var selectedEvents: events.filter(e => e.day === selectedKey)
    readonly property int weekCount: {
        const firstWeekday = (new Date(viewYear, viewMonth, 1, 12).getDay() + 6) % 7;
        const daysInMonth = new Date(viewYear, viewMonth + 1, 0, 12).getDate();
        return Math.ceil((firstWeekday + daysInMonth) / 7);
    }
    readonly property var calendarDays: buildDays()

    implicitWidth: 380
    implicitHeight: 335 + weekCount * 39
    visible: false
    color: "transparent"
    grabFocus: true // clicking outside dismisses the popup

    function dayKey(date) {
        function pad(n) { return String(n).padStart(2, "0"); }
        return date.getFullYear() + "-" + pad(date.getMonth() + 1) + "-" + pad(date.getDate());
    }

    function buildDays() {
        const firstWeekday = (new Date(viewYear, viewMonth, 1, 12).getDay() + 6) % 7;
        const cells = [];
        const numberOfCells = weekCount * 7;
        for (let i = 0; i < numberOfCells; ++i) {
            const date = new Date(viewYear, viewMonth, 1 - firstWeekday + i, 12);
            cells.push({
                year: date.getFullYear(),
                month: date.getMonth(),
                day: date.getDate(),
                key: dayKey(date),
                currentMonth: date.getMonth() === viewMonth
            });
        }
        return cells;
    }

    function selectDay(year, month, day) {
        const newDate = new Date(year, month, day, 12);
        const changedMonth = newDate.getFullYear() !== viewYear || newDate.getMonth() !== viewMonth;
        selectedDate = newDate;
        if (changedMonth) {
            viewYear = newDate.getFullYear();
            viewMonth = newDate.getMonth();
            monthAppear.restart();
            monthFetchDebounce.restart();
        }
    }

    function navigateMonth(delta) {
        const previousDay = selectedDate.getDate();
        const target = new Date(viewYear, viewMonth + delta, 1, 12);
        const daysInTarget = new Date(target.getFullYear(), target.getMonth() + 1, 0, 12).getDate();
        selectDay(target.getFullYear(), target.getMonth(), Math.min(previousDay, daysInTarget));
    }

    function goToday() {
        const today = new Date();
        selectDay(today.getFullYear(), today.getMonth(), today.getDate());
    }

    function toggle() {
        if (visible) {
            visible = false;
        } else {
            const today = new Date();
            selectedDate = new Date(today.getFullYear(), today.getMonth(), today.getDate(), 12);
            viewYear = today.getFullYear();
            viewMonth = today.getMonth();
            visible = true;
            refreshEvents();
            panel.opacity = 0;
            opening.restart();
        }
    }

    function refreshEvents() {
        if (!visible || calendarDays.length === 0) return;
        const first = calendarDays[0];
        const last = calendarDays[calendarDays.length - 1];
        const dayAfter = new Date(last.year, last.month, last.day + 1, 12);
        status = "loading";
        statusMessage = "";
        events = [];
        // Explicit path: works even if systemd --user lacks ~/.nix-profile/bin in PATH.
        // Installed by our Home Manager quickshell.nix module.
        eventLoader.exec([
            Quickshell.env("HOME") + "/.nix-profile/bin/qs-calendar-events",
            "--start", first.key,
            "--end", dayKey(dayAfter)
        ]);
    }

    Process {
        id: eventLoader
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const payload = JSON.parse(this.text);
                    popup.events = payload.events || [];
                    popup.status = payload.status || "error";
                    popup.statusMessage = payload.message || "";
                } catch (error) {
                    popup.status = "error";
                    popup.statusMessage = "Could not load calendar events.";
                }
            }
        }
    }

    Timer {
        id: monthFetchDebounce
        interval: 180
        repeat: false
        onTriggered: popup.refreshEvents()
    }

    SequentialAnimation {
        id: opening
        NumberAnimation {
            target: panel
            property: "opacity"
            from: 0
            to: 1
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    SequentialAnimation {
        id: monthAppear
        NumberAnimation {
            target: monthGrid
            property: "opacity"
            from: 0.55
            to: 1
            duration: 160
            easing.type: Easing.OutQuad
        }
    }

    Rectangle {
        id: panel
        anchors.fill: parent
        radius: 13
        color: Qt.rgba(popup.backgroundColor.r, popup.backgroundColor.g, popup.backgroundColor.b, 0.97)
        border.width: 1
        border.color: Qt.rgba(popup.foregroundColor.r, popup.foregroundColor.g, popup.foregroundColor.b, 0.13)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            // Month title and navigation. Both arrow clicks and mouse wheel work.
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: Qt.formatDate(new Date(popup.viewYear, popup.viewMonth, 1, 12), "MMMM yyyy")
                    font.pixelSize: 18
                    font.bold: true
                    color: popup.foregroundColor
                }

                Rectangle {
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 27
                    radius: 7
                    color: todayMouse.containsMouse ? popup.secondaryColor
                                                    : Qt.rgba(popup.secondaryColor.r, popup.secondaryColor.g, popup.secondaryColor.b, 0.35)
                    Text { anchors.centerIn: parent; text: "Today"; color: popup.foregroundColor; font.pixelSize: 11; font.bold: true }
                    MouseArea {
                        id: todayMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: popup.goToday()
                    }
                }
                Repeater {
                    model: ["‹", "›"]
                    delegate: Rectangle {
                        id: arrow
                        required property string modelData
                        required property int index
                        Layout.preferredWidth: 30
                        Layout.preferredHeight: 30
                        radius: 8
                        color: arrowMouse.containsMouse
                            ? Qt.rgba(popup.accentColor.r, popup.accentColor.g, popup.accentColor.b, 0.32)
                            : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: arrow.modelData
                            font.pixelSize: 24
                            color: popup.foregroundColor
                        }
                        MouseArea {
                            id: arrowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: popup.navigateMonth(arrow.index === 0 ? -1 : 1)
                        }
                    }
                }
            }

            Row {
                Layout.fillWidth: true
                Layout.preferredHeight: 20
                spacing: 4
                Repeater {
                    model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                    delegate: Text {
                        required property string modelData
                        width: (popup.implicitWidth - 32 - 6 * 4) / 7
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        color: Qt.rgba(popup.foregroundColor.r, popup.foregroundColor.g, popup.foregroundColor.b, 0.65)
                        font.pixelSize: 11
                        font.bold: true
                    }
                }
            }

            Grid {
                id: monthGrid
                Layout.fillWidth: true
                Layout.preferredHeight: popup.weekCount * 39
                columns: 7
                spacing: 4

                WheelHandler {
                    target: null
                    onWheel: (event) => {
                        // Touchpad gestures can send many small wheel events.
                        // Limit navigation to approximately one month per gesture.
                        const now = Date.now();
                        if (now - popup.lastScrollMs > 240) {
                            if (event.angleDelta.y > 0) popup.navigateMonth(-1);
                            else if (event.angleDelta.y < 0) popup.navigateMonth(1);
                            popup.lastScrollMs = now;
                        }
                        event.accepted = true;
                    }
                }

                Repeater {
                    model: popup.calendarDays
                    delegate: Rectangle {
                        id: dateCell
                        required property var modelData
                        readonly property bool chosen: modelData.key === popup.selectedKey
                        readonly property bool isToday: modelData.key === popup.todayKey
                        readonly property bool hasEvents: popup.events.some(e => e.day === modelData.key)
                        width: (popup.implicitWidth - 32 - 6 * 4) / 7
                        height: 35
                        radius: 9
                        color: chosen ? popup.accentColor : (dayMouse.containsMouse
                            ? Qt.rgba(popup.accentColor.r, popup.accentColor.g, popup.accentColor.b, 0.17)
                            : "transparent")
                        border.width: isToday && !chosen ? 1 : 0
                        border.color: popup.accentColor
                        Behavior on color { ColorAnimation { duration: 140 } }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: 6
                            text: dateCell.modelData.day
                            font.pixelSize: 13
                            font.bold: dateCell.chosen || dateCell.isToday
                            color: dateCell.chosen ? popup.backgroundColor
                                  : dateCell.modelData.currentMonth ? popup.foregroundColor
                                  : Qt.rgba(popup.foregroundColor.r, popup.foregroundColor.g, popup.foregroundColor.b, 0.37)
                        }
                        Rectangle {
                            visible: dateCell.hasEvents
                            width: 4
                            height: 4
                            radius: 2
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 4
                            color: dateCell.chosen ? popup.backgroundColor : popup.accentColor
                        }
                        MouseArea {
                            id: dayMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: popup.selectDay(dateCell.modelData.year, dateCell.modelData.month, dateCell.modelData.day)
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Qt.rgba(popup.foregroundColor.r, popup.foregroundColor.g, popup.foregroundColor.b, 0.15)
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                Text {
                    Layout.fillWidth: true
                    text: popup.selectedKey === popup.todayKey
                        ? "Today's events"
                        : Qt.formatDate(popup.selectedDate, "ddd, d MMM")
                    font.pixelSize: 15
                    font.bold: true
                    color: popup.foregroundColor
                }
                Text {
                    text: popup.selectedEvents.length + (popup.selectedEvents.length === 1 ? " event" : " events")
                    font.pixelSize: 11
                    color: Qt.rgba(popup.foregroundColor.r, popup.foregroundColor.g, popup.foregroundColor.b, 0.65)
                }
            }

            Flickable {
                id: agenda
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                contentWidth: width
                contentHeight: agendaColumn.implicitHeight

                Column {
                    id: agendaColumn
                    width: agenda.width
                    spacing: 6

                    Text {
                        visible: popup.selectedEvents.length === 0
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: popup.status === "loading" ? "Loading events..."
                              : popup.status === "unconfigured" ? "Add your Google Calendar feed to show events."
                              : "No events for this day"
                        font.pixelSize: 13
                        color: Qt.rgba(popup.foregroundColor.r, popup.foregroundColor.g, popup.foregroundColor.b, 0.66)
                        topPadding: 10
                    }

                    Repeater {
                        model: popup.selectedEvents
                        delegate: Rectangle {
                            id: eventCard
                            required property var modelData
                            width: agenda.width
                            height: modelData.location ? 60 : 44
                            radius: 8
                            color: Qt.rgba(popup.secondaryColor.r, popup.secondaryColor.g, popup.secondaryColor.b, 0.18)

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.topMargin: 7
                                anchors.bottomMargin: 7
                                width: 3
                                radius: 2
                                color: popup.accentColor
                            }

                            Column {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 12
                                anchors.rightMargin: 9
                                spacing: 4
                                Row {
                                    width: parent.width
                                    spacing: 8
                                    Text {
                                        width: 63
                                        text: eventCard.modelData.time
                                        elide: Text.ElideRight
                                        color: popup.accentColor
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                    Text {
                                        width: parent.width - 63 - 8
                                        text: eventCard.modelData.title
                                        elide: Text.ElideRight
                                        color: popup.foregroundColor
                                        font.pixelSize: 12
                                        font.bold: true
                                    }
                                }
                                Text {
                                    visible: eventCard.modelData.location !== ""
                                    text: eventCard.modelData.location
                                    width: parent.width
                                    elide: Text.ElideRight
                                    color: Qt.rgba(popup.foregroundColor.r, popup.foregroundColor.g, popup.foregroundColor.b, 0.65)
                                    font.pixelSize: 11
                                }
                            }
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: popup.status === "stale" || popup.status === "partial" || popup.status === "error"
                text: popup.statusMessage
                elide: Text.ElideRight
                color: popup.accentColor
                font.pixelSize: 10
            }
        }
    }
}
