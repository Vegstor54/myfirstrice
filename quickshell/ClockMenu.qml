import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Меню часов: выезжает из-под бара по клику на часы.
// Слева вертикальный ползунок громкости, в середине плеер (обложка, трек, кнопки),
// справа крупное время с часовым поясом и календарь.
// Закрывается кликом вне меню или Esc.
Scope {
    id: root

    property bool shown: false
    // Имя монитора, на котором открыто меню, и центр часов на экране: под ними выезжает карточка
    property string monitor: ""
    property real anchorX: 100000

    // Название часового пояса (Asia/Vladivostok), читается один раз
    property string timezone: ""

    readonly property var weekdays: ["воскресенье", "понедельник", "вторник", "среда", "четверг", "пятница", "суббота"]
    readonly property var monthsGen: ["января", "февраля", "марта", "апреля", "мая", "июня",
                                      "июля", "августа", "сентября", "октября", "ноября", "декабря"]

    function toggle(monitorName, centerX) {
        if (shown && monitor === monitorName) {
            shown = false
            return
        }
        monitor = monitorName
        if (centerX !== undefined) anchorX = centerX
        shown = true
    }

    function two(n) { return String(n).padStart(2, "0") }

    // «UTC+10», «UTC+5:30»
    function utcLabel(d) {
        const m = -d.getTimezoneOffset()
        const a = Math.abs(m)
        return "UTC" + (m < 0 ? "-" : "+") + Math.floor(a / 60) + (a % 60 ? ":" + two(a % 60) : "")
    }

    Process {
        command: ["timedatectl", "show", "-p", "Timezone", "--value"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.timezone = text.trim()
        }
    }

    // Секунды нужны, только пока меню открыто
    SystemClock {
        id: clock
        precision: root.shown ? SystemClock.Seconds : SystemClock.Minutes
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            readonly property bool isTarget: root.monitor === modelData.name

            visible: isTarget && (root.shown || fade.running)
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: (root.shown && isTarget) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            Connections {
                target: root
                function onShownChanged() {
                    if (root.shown && win.isTarget) {
                        catcher.forceActiveFocus()
                        calendar.reset()
                    }
                }
            }

            // Прозрачный фон на весь экран, в том числе поверх бара: клик вне меню закрывает его
            Item {
                id: catcher
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: root.shown = false

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.shown = false
                }
            }

            Rectangle {
                id: card
                property real slide: root.shown ? 0 : -16

                anchors.top: parent.top
                // Под баром: 8 — его отступ от края, ещё 8 — зазор до меню
                anchors.topMargin: Settings.barHeight + 16 + slide
                // Стоит под часами, но не выходит за края экрана
                x: Math.max(Settings.barSideMargin,
                            Math.min(parent.width - width - Settings.barSideMargin, root.anchorX - width / 2))
                width: 700
                height: 400
                radius: 24
                color: Qt.rgba(Colors.surfaceContainer.r, Colors.surfaceContainer.g, Colors.surfaceContainer.b, 0.95)
                border.width: 1
                border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.35)
                opacity: root.shown ? 1 : 0

                Behavior on opacity { NumberAnimation { id: fade; duration: 180; easing.type: Easing.OutCubic } }
                Behavior on slide   { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                // Клики по карточке не должны закрывать меню
                MouseArea { anchors.fill: parent }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 16

                    // 1. Громкость
                    VolumeSlider {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 48
                    }

                    // 2. Плеер (грузится через Loader: см. MediaPlayer.qml)
                    Item {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 200

                        Loader {
                            id: player
                            anchors.fill: parent
                            active: win.isTarget && root.shown
                            source: "MediaPlayer.qml"
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: player.status === Loader.Error
                            text: "Плеер недоступен"
                            color: Colors.text
                            opacity: 0.6
                            font.family: Settings.uiFontFamily
                            font.pixelSize: 12
                        }
                    }

                    // 3. Время, часовой пояс и календарь
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 4

                        RowLayout {
                            spacing: 6
                            Text {
                                text: root.two(clock.date.getHours()) + ":" + root.two(clock.date.getMinutes())
                                color: Colors.text
                                font.family: Settings.uiFontFamily
                                font.pixelSize: 64
                                font.bold: true
                                Layout.alignment: Qt.AlignBaseline
                            }
                            Text {
                                text: ":" + root.two(clock.date.getSeconds())
                                color: Colors.text
                                opacity: 0.6
                                font.family: Settings.uiFontFamily
                                font.pixelSize: 24
                                Layout.alignment: Qt.AlignBaseline
                            }
                        }

                        Text {
                            text: root.weekdays[clock.date.getDay()] + ", " + clock.date.getDate() + " "
                                + root.monthsGen[clock.date.getMonth()]
                            color: Colors.text
                            font.family: Settings.uiFontFamily
                            font.pixelSize: 15
                        }

                        Text {
                            text: (root.timezone !== "" ? root.timezone.replace(/_/g, " ") + " · " : "")
                                + root.utcLabel(clock.date)
                            color: Colors.text
                            opacity: 0.6
                            font.family: Settings.uiFontFamily
                            font.pixelSize: 12
                        }

                        Item { Layout.preferredHeight: 8 }

                        CalendarView {
                            id: calendar
                            Layout.fillWidth: true
                            today: clock.date
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }
        }
    }
}
