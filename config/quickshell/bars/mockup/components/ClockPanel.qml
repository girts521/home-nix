import Quickshell
import Quickshell.Io
import QtQuick

BarPanel {
    id: panel
    required property var now

    bg: panel.bgColor
    fg: panel.fgColor
    accent: panel.accentColor
    secondary: panel.secondaryColor
    panelWidth: 372
    contentSpacing: 14

    property color bgColor: "#122957"
    property color fgColor: "#c6cff5"
    property color accentColor: "#8e81d9"
    property color secondaryColor: "#3f5ac8"

    property int viewYear: now.getFullYear()
    property int viewMonth: now.getMonth()
    property var selectedDate: new Date(now.getFullYear(), now.getMonth(), now.getDate())
    readonly property string selectedDateKey: selectedDate.getFullYear() + "-" + selectedDate.getMonth() + "-" + selectedDate.getDate()
    property string timeZoneName: "Europe/Berlin"
    property string timeZoneLabel: "Berlin, Germany (CET/CEST)"
    property int weatherTemperature: 0
    property int weatherCode: -1
    property bool weatherIsDay: true
    property bool weatherAvailable: false
    property string weatherLastUpdated: ""

    readonly property string weatherIcon: {
        if (!weatherIsDay && (weatherCode === 0 || weatherCode === 1)) return "moon";
        if (weatherCode === 0) return "sun";
        if (weatherCode <= 3) return "cloud-sun";
        if (weatherCode <= 48) return "cloud-fog";
        if (weatherCode <= 67 || (weatherCode >= 80 && weatherCode <= 82)) return "cloud-rain";
        if (weatherCode <= 77 || (weatherCode >= 85 && weatherCode <= 86)) return "cloud-snow";
        if (weatherCode >= 95) return "cloud-lightning";
        return "cloud";
    }
    readonly property string weatherDescription: {
        if (!weatherAvailable) return "Waiting for current conditions";
        if (weatherCode === 0) return weatherIsDay ? "Clear skies" : "Clear night";
        if (weatherCode === 1) return weatherIsDay ? "Mostly clear" : "Mostly clear night";
        if (weatherCode === 2) return "Partly cloudy";
        if (weatherCode === 3) return "Overcast";
        if (weatherCode === 45 || weatherCode === 48) return "Foggy";
        if (weatherCode >= 51 && weatherCode <= 55) return "Light drizzle";
        if (weatherCode >= 56 && weatherCode <= 57) return "Freezing drizzle";
        if (weatherCode >= 61 && weatherCode <= 65) return "Rain";
        if (weatherCode >= 66 && weatherCode <= 67) return "Freezing rain";
        if (weatherCode >= 71 && weatherCode <= 77) return "Snowfall";
        if (weatherCode === 80) return "Light showers";
        if (weatherCode >= 81 && weatherCode <= 82) return "Rain showers";
        if (weatherCode === 85 || weatherCode === 86) return "Snow showers";
        if (weatherCode === 95) return "Thunderstorm";
        if (weatherCode === 96 || weatherCode === 99) return "Thunderstorm · hail";
        return "Current conditions";
    }
    readonly property color weatherTint: {
        if (weatherCode >= 95) return "#fbbf24";
        if ((weatherCode >= 51 && weatherCode <= 67) || (weatherCode >= 80 && weatherCode <= 82)) return "#7dd3fc";
        if ((weatherCode >= 71 && weatherCode <= 77) || (weatherCode >= 85 && weatherCode <= 86)) return "#bfdbfe";
        if (weatherCode === 45 || weatherCode === 48 || weatherCode === 3) return "#cbd5e1";
        return "#fcd34d";
    }
    readonly property bool rainEffect: weatherAvailable && (
        (weatherCode >= 51 && weatherCode <= 67) || (weatherCode >= 80 && weatherCode <= 82) || weatherCode >= 95)
    readonly property bool snowEffect: weatherAvailable && ((weatherCode >= 71 && weatherCode <= 77) || (weatherCode >= 85 && weatherCode <= 86))
    readonly property bool stormEffect: weatherAvailable && weatherCode >= 95
    property int weatherAnimationPhase: 0

    Process {
        id: weatherProcess
        command: ["python3", Quickshell.shellDir + "/components/weather.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const current = JSON.parse(this.text);
                    panel.weatherTemperature = current.temperature;
                    panel.weatherCode = current.code;
                    panel.weatherIsDay = current.isDay;
                    panel.weatherAvailable = true;
                    panel.weatherLastUpdated = Qt.formatDateTime(new Date(), "hh:mm");
                } catch (e) {
                    panel.weatherAvailable = false;
                    console.warn("Could not parse Berlin weather:", e);
                }
            }
        }
        onExited: (code, status) => {
            if (code !== 0) panel.weatherAvailable = false;
        }
    }
    Timer {
        interval: 15 * 60 * 1000
        running: panel.open
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!weatherProcess.running) weatherProcess.running = true
    }
    // Decorative movement is clipped to the weather card; it never claims to
    // represent a live radar or forecast and is only animated while open.
    Timer {
        interval: 110
        running: panel.open && panel.weatherAvailable
        repeat: true
        onTriggered: panel.weatherAnimationPhase = (panel.weatherAnimationPhase + 1) % 100
    }

    readonly property var monthNames: ["January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"]

    function daysIn(year, month) { return new Date(year, month + 1, 0).getDate(); }
    // The reference calendar starts its weeks on Sunday.
    function leadIn(year, month) { return new Date(year, month, 1).getDay(); }
    function calendarCells() {
        return leadIn(viewYear, viewMonth) + daysIn(viewYear, viewMonth);
    }
    function selectDate(date) {
        selectedDate = new Date(date.getFullYear(), date.getMonth(), date.getDate());
        console.info("Calendar date selected:", Qt.formatDate(selectedDate, Qt.ISODate));
    }

    // A compact hero forecast card: prominent condition artwork and temperature,
    // with weather-themed ambience clipped inside the card rather than a generic
    // random animation. Real weather values always come from Open-Meteo above.
    Item {
        id: weatherCard
        width: parent.width
        height: 112

        Rectangle {
            anchors.fill: parent
            radius: 12
            clip: true
            gradient: Gradient {
                GradientStop { position: 0; color: panel.stormEffect ? "#26355c" : (panel.rainEffect || panel.snowEffect ? "#1c4770" : "#314a83") }
                GradientStop { position: 1; color: panel.stormEffect ? "#172744" : (panel.rainEffect || panel.snowEffect ? "#102c50" : "#1b315e") }
            }
            border.width: 1
            border.color: Qt.rgba(panel.weatherTint.r, panel.weatherTint.g, panel.weatherTint.b, 0.32)

            // Soft weather halo.
            Rectangle {
                id: weatherGlow
                width: 132; height: 132; radius: 66
                x: 26 + (panel.weatherAnimationPhase % 20) - 10
                y: -38
                color: Qt.rgba(panel.weatherTint.r, panel.weatherTint.g, panel.weatherTint.b, 0.10)
                border.width: 1
                border.color: Qt.rgba(panel.weatherTint.r, panel.weatherTint.g, panel.weatherTint.b, 0.14)
                Behavior on x { NumberAnimation { duration: 600; easing.type: Easing.InOutSine } }
            }
            Rectangle {
                width: 92; height: 92; radius: 46
                x: weatherGlow.x + 18; y: weatherGlow.y + 16
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(panel.weatherTint.r, panel.weatherTint.g, panel.weatherTint.b, 0.12)
            }

            // Raindrops / snow flecks drift down in actual precipitation types.
            Repeater {
                model: panel.rainEffect ? 16 : (panel.snowEffect ? 12 : 0)
                delegate: Rectangle {
                    required property int index
                    property real lane: (index * 47 + 17) % Math.max(1, weatherCard.width)
                    x: lane + (panel.stormEffect ? (index % 3 - 1) * 4 : 0)
                    y: ((index * 29 + panel.weatherAnimationPhase * (panel.snowEffect ? 1.1 : 2.9)) % (weatherCard.height + 24)) - 18
                    width: panel.snowEffect ? (index % 3 + 2) : 2
                    height: panel.snowEffect ? width : 9
                    radius: panel.snowEffect ? width / 2 : 1
                    rotation: panel.snowEffect ? 0 : -14
                    color: Qt.rgba(panel.weatherTint.r, panel.weatherTint.g, panel.weatherTint.b, panel.snowEffect ? 0.62 : 0.34)
                }
            }

            // Occasional lightning flash for thunder; a subdued pulse rather
            // than a continuously flashing full panel.
            Rectangle {
                anchors.fill: parent
                radius: 12
                color: "#dbeafe"
                opacity: panel.stormEffect && panel.weatherAnimationPhase % 37 < 2 ? 0.12 : 0
                Behavior on opacity { NumberAnimation { duration: 90 } }
            }

            Row {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 14

                Item {
                    width: 86
                    height: parent.height
                    anchors.verticalCenter: parent.verticalCenter
                    Icon {
                        id: heroIcon
                        anchors.centerIn: parent
                        name: panel.weatherAvailable ? panel.weatherIcon : "cloud"
                        tone: "sky"
                        size: 64
                        scale: 1 + (panel.weatherAvailable && !panel.rainEffect && !panel.snowEffect ? 0.045 : 0.02) * Math.sin(panel.weatherAnimationPhase * 0.09)
                        transformOrigin: Item.Center
                        Behavior on scale { NumberAnimation { duration: 900; easing.type: Easing.InOutSine } }
                    }
                    Rectangle {
                        anchors.horizontalCenter: heroIcon.horizontalCenter
                        y: heroIcon.y + heroIcon.height - 2
                        width: 56; height: 9; radius: 5
                        color: Qt.rgba(panel.weatherTint.r, panel.weatherTint.g, panel.weatherTint.b, 0.24)
                        scale: 1 + 0.12 * Math.sin(panel.weatherAnimationPhase * 0.09)
                        opacity: panel.weatherAvailable ? 0.8 : 0.25
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1
                    Text {
                        text: panel.weatherAvailable ? (panel.weatherTemperature + "°") : "—°"
                        color: "#ffffff"
                        font.pixelSize: 34
                        font.weight: Font.DemiBold
                        font.family: panel.uiFont
                    }
                    Text {
                        text: panel.weatherDescription
                        color: panel.weatherTint
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        font.family: panel.uiFont
                    }
                    Text {
                        text: "Berlin  ·  " + (panel.weatherAvailable ? panel.weatherLastUpdated : "Open-Meteo")
                        color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.66)
                        font.pixelSize: 10
                        font.family: panel.uiFont
                    }
                }

                Item { width: 1; height: 1 }
            }
        }
    }

    Item {
        width: parent.width
        height: 42

        Column {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1
            Text {
                text: panel.monthNames[panel.viewMonth] + " " + panel.viewYear
                color: panel.accent
                font.bold: true
                font.pixelSize: 14
                font.family: panel.uiFont
            }
            Text {
                text: "Berlin, Germany (CET/CEST)"
                color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.6)
                font.pixelSize: 10
                font.family: panel.uiFont
            }
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            Repeater {
                model: [-1, 1]
                delegate: Item {
                    required property int modelData
                    width: 24
                    height: 24
                    Rectangle {
                        anchors.fill: parent
                        radius: 4
                        color: navMouse.containsMouse
                               ? Qt.rgba(panel.secondary.r, panel.secondary.g, panel.secondary.b, 0.3)
                               : "transparent"
                    }
                    Icon {
                        anchors.centerIn: parent
                        name: modelData < 0 ? "chevron-left" : "chevron-right"
                        tone: "fg"
                        size: 16
                    }
                    MouseArea {
                        id: navMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            let month = panel.viewMonth + modelData;
                            let year = panel.viewYear;
                            if (month < 0) { month = 11; year -= 1; }
                            if (month > 11) { month = 0; year += 1; }
                            panel.viewMonth = month;
                            panel.viewYear = year;
                        }
                    }
                }
            }
        }
    }

    Grid {
        id: calendarGrid
        width: parent.width
        columns: 7
        spacing: 4

        Repeater {
            model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
            delegate: Text {
                required property string modelData
                width: (calendarGrid.width - 24) / 7
                height: 16
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.4)
                font.pixelSize: 10
                font.family: "monospace"
            }
        }

        Repeater {
            model: panel.calendarCells()
            delegate: Rectangle {
                required property int index
                readonly property int leadingDays: panel.leadIn(panel.viewYear, panel.viewMonth)
                readonly property int day: index - leadingDays + 1
                readonly property int dayCount: panel.daysIn(panel.viewYear, panel.viewMonth)
                readonly property bool inMonth: day >= 1 && day <= dayCount
                readonly property bool isSelected: inMonth && day === panel.selectedDate.getDate()
                    && panel.viewMonth === panel.selectedDate.getMonth()
                    && panel.viewYear === panel.selectedDate.getFullYear()
                Accessible.role: Accessible.Button
                Accessible.name: Qt.formatDate(new Date(panel.viewYear, panel.viewMonth, day), "MMMM d")
                Accessible.description: isSelected ? "Selected date" : "Select date"
                Accessible.focusable: inMonth
                Accessible.onPressAction: if (inMonth) panel.selectDate(new Date(panel.viewYear, panel.viewMonth, day))
                readonly property bool isToday: inMonth && day === panel.now.getDate()
                    && panel.viewMonth === panel.now.getMonth() && panel.viewYear === panel.now.getFullYear()
                width: (calendarGrid.width - 24) / 7
                height: 26
                radius: 4
                color: isSelected ? panel.accent
                    : (dayMouse.containsMouse && inMonth
                        ? Qt.rgba(panel.secondary.r, panel.secondary.g, panel.secondary.b, 0.3)
                        : "transparent")

                Text {
                    anchors.centerIn: parent
                    text: {
                        if (inMonth) return day;
                        if (day < 1) return new Date(panel.viewYear, panel.viewMonth, 0).getDate() + day;
                        return "";
                    }
                    color: isSelected ? "#ffffff"
                        : (inMonth ? panel.fg : Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.2))
                    font.pixelSize: 11
                    font.family: "monospace"
                    font.bold: isSelected
                }
                MouseArea {
                    id: dayMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: inMonth
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: panel.selectDate(new Date(panel.viewYear, panel.viewMonth, day))
                }
            }
        }
    }

    Column {
        width: parent.width
        spacing: 8
        Item { width: 1; height: 8 }
        Rectangle {
            width: parent.width
            height: 1
            color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.1)
        }
        Text {
            text: "Agenda · " + Qt.formatDate(panel.selectedDate, "MMM d")
            color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.6)
            font.pixelSize: 10
            font.bold: true
            font.capitalization: Font.AllUppercase
            font.family: panel.uiFont
        }
        Rectangle {
            width: parent.width
            height: 42
            radius: 8
            color: Qt.rgba(panel.secondary.r, panel.secondary.g, panel.secondary.b, 0.2)
            Rectangle {
                width: 2
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                radius: 1
                color: panel.accent
            }
            Text {
                anchors.centerIn: parent
                text: "No events scheduled"
                color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.6)
                font.pixelSize: 11
                font.family: panel.uiFont
            }
        }
    }
}
