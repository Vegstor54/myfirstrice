import QtQuick
import QtQuick.Layouts
import ".."

// Компактная строка микшера: название, проценты, кнопка выключения звука и слайдер.
// Используется для устройств вывода и для приложений (StreamRow.qml).
// Слайдер: клик и перетаскивание, колесо меняет на 5%.
ColumnLayout {
    id: row
    property string title: ""
    property real value: 0
    property bool muted: false
    // Выделенная строка (например, устройство вывода по умолчанию)
    property bool highlighted: false
    // Подпись справа от названия мелким шрифтом («по умолчанию» и т.п.)
    property string badge: ""
    // Нажатие на название (у устройств: сделать выходом по умолчанию)
    property bool titleClickable: false
    signal setValue(real v)
    signal step(real d)
    signal toggleMute()
    signal titleClicked()

    spacing: 4

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            Layout.fillWidth: true
            text: row.title
            elide: Text.ElideRight
            color: row.highlighted ? Colors.primary : Colors.text
            font.family: Settings.uiFontFamily
            font.pixelSize: 13
            font.bold: row.highlighted

            KeyboardMouseArea {
                anchors.fill: parent
                enabled: row.titleClickable
                cursorShape: row.titleClickable ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: row.titleClicked()
            }
        }

        Text {
            visible: row.badge !== ""
            text: row.badge
            color: Colors.text
            opacity: 0.6
            font.family: Settings.uiFontFamily
            font.pixelSize: 11
        }

        Text {
            text: Math.round(row.value * 100) + "%"
            color: Colors.text
            font.family: Settings.uiFontFamily
            font.pixelSize: 12
        }

        // Кнопка «выключить звук»: динамик (U+F028) или перечёркнутый (U+F026)
        Rectangle {
            Layout.preferredWidth: 26
            Layout.preferredHeight: 26
            radius: Settings.r(13)
            color: row.muted ? Colors.primary
                 : muteMouse.containsMouse ? Settings.fillHover
                 : Settings.fill
            border.width: 0

            Text {
                anchors.centerIn: parent
                text: row.muted ? "" : ""
                color: row.muted ? Colors.textOnPrimary : Colors.text
                font.family: "Symbols Nerd Font"
                font.pixelSize: 12
            }
            KeyboardMouseArea {
                id: muteMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: row.toggleMute()
            }
        }
    }

    Item {
        id: slider
        Layout.fillWidth: true
        Layout.preferredHeight: 22
        activeFocusOnTab: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Right || event.key === Qt.Key_Up) {
                row.step(0.05)
                event.accepted = true
            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Down) {
                row.step(-0.05)
                event.accepted = true
            } else if (event.key === Qt.Key_Home) {
                row.setValue(0)
                event.accepted = true
            } else if (event.key === Qt.Key_End) {
                row.setValue(1)
                event.accepted = true
            }
        }

        readonly property real knob: 16

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 6
            radius: Settings.r(3)
            color: Colors.surfaceContainerHighest
            border.width: slider.activeFocus ? 2 : 0
            border.color: Colors.primary

            Rectangle {
                width: row.value * (slider.width - slider.knob) + slider.knob / 2
                height: parent.height
                radius: Settings.r(3)
                color: row.muted ? Colors.mutedFill : Colors.primary
            }
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: row.value * (slider.width - slider.knob)
            width: slider.knob
            height: slider.knob
            radius: Settings.r(slider.knob / 2)
            color: row.muted ? Colors.mutedFill : Colors.primary
            border.width: 2
            border.color: Colors.surfaceContainer
        }

        KeyboardMouseArea {
            anchors.fill: parent
            keyboardEnabled: false
            preventStealing: true
            cursorShape: Qt.PointingHandCursor

            function setFrom(mx) {
                row.setValue((mx - slider.knob / 2) / (slider.width - slider.knob))
            }

            onPressed: mouse => setFrom(mouse.x)
            onPositionChanged: mouse => { if (pressed) setFrom(mouse.x) }
            onWheel: wheel => row.step(wheel.angleDelta.y > 0 ? 0.05 : -0.05)
        }
    }
}
