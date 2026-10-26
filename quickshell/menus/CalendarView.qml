import QtQuick
import QtQuick.Layouts
import ".."

// Календарь на месяц: неделя с понедельника, сегодняшний день выделен.
// Стрелки листают месяцы, клик по названию возвращает к текущему.
ColumnLayout {
    id: cal

    // Сегодняшняя дата (передаёт ClockMenu)
    property date today: new Date()
    property int viewYear: today.getFullYear()
    property int viewMonth: today.getMonth()

    readonly property var monthNames: ["Январь", "Февраль", "Март", "Апрель", "Май", "Июнь",
                                       "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь"]
    readonly property var dayNames: ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]

    // Сколько клеток нужно до первого числа: неделя начинается с понедельника
    readonly property int offset: (new Date(viewYear, viewMonth, 1).getDay() + 6) % 7

    function reset() {
        viewYear = today.getFullYear()
        viewMonth = today.getMonth()
    }

    function shift(delta) {
        const d = new Date(viewYear, viewMonth + delta, 1)
        viewYear = d.getFullYear()
        viewMonth = d.getMonth()
    }

    spacing: 6

    RowLayout {
        Layout.fillWidth: true

        Rectangle {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            radius: Settings.r(14)
            color: prevMouse.containsMouse ? Colors.surfaceContainerHighest : "transparent"
            Text {
                anchors.centerIn: parent
                text: "‹"
                color: Colors.text
                font.family: Settings.uiFontFamily
                font.pixelSize: 18
            }
            MouseArea {
                id: prevMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: cal.shift(-1)
            }
        }

        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: cal.monthNames[cal.viewMonth] + " " + cal.viewYear
            color: Colors.text
            font.family: Settings.uiFontFamily
            font.pixelSize: 14
            font.bold: true

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: cal.reset()
            }
        }

        Rectangle {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            radius: Settings.r(14)
            color: nextMouse.containsMouse ? Colors.surfaceContainerHighest : "transparent"
            Text {
                anchors.centerIn: parent
                text: "›"
                color: Colors.text
                font.family: Settings.uiFontFamily
                font.pixelSize: 18
            }
            MouseArea {
                id: nextMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: cal.shift(1)
            }
        }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 7
        rowSpacing: 2
        columnSpacing: 2

        Repeater {
            model: cal.dayNames

            Text {
                required property string modelData
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                color: Colors.text
                opacity: 0.5
                font.family: Settings.uiFontFamily
                font.pixelSize: 11
            }
        }

        // 6 недель по 7 дней: дни соседних месяцев приглушены
        Repeater {
            model: 42

            Rectangle {
                id: cell
                required property int index
                readonly property date day: new Date(cal.viewYear, cal.viewMonth, 1 - cal.offset + index)
                readonly property bool inMonth: day.getMonth() === cal.viewMonth
                readonly property bool isToday: day.getFullYear() === cal.today.getFullYear()
                    && day.getMonth() === cal.today.getMonth() && day.getDate() === cal.today.getDate()

                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.preferredHeight: 26
                radius: Settings.r(13)
                color: isToday ? Colors.primary : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: cell.day.getDate()
                    color: cell.isToday ? Colors.textOnPrimary : Colors.text
                    opacity: cell.inMonth ? 1 : 0.3
                    font.family: Settings.uiFontFamily
                    font.pixelSize: 12
                    font.bold: cell.isToday
                }
            }
        }
    }
}
