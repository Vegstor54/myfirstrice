import QtQuick
import QtQuick.Layouts
import ".."

// Блок управления громкостью: заголовок с процентами, слайдер и кнопка выключения.
// Слайдер: клик и перетаскивание, колесо меняет на 5%.
ColumnLayout {
    id: ctl
    property string title: ""
    property real value: 0
    property bool muted: false
    property string muteLabel: ""
    property string mutedLabel: ""
    signal setValue(real v)
    signal step(real d)
    signal toggleMute()

    spacing: 8

    RowLayout {
        Layout.fillWidth: true

        Text {
            text: ctl.title
            color: Colors.text
            font.family: Settings.uiFontFamily
            font.pixelSize: 14
            font.bold: true
        }
        Item { Layout.fillWidth: true }
        Text {
            text: Math.round(ctl.value * 100) + "%"
            color: Colors.text
            font.family: Settings.uiFontFamily
            font.pixelSize: 14
        }
    }

    Item {
        id: slider
        Layout.fillWidth: true
        Layout.preferredHeight: 28

        readonly property real knob: 20

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 8
            radius: Settings.r(4)
            color: Colors.surfaceContainerHighest
            border.width: 1
            border.color: Colors.border

            Rectangle {
                width: ctl.value * (slider.width - slider.knob) + slider.knob / 2
                height: parent.height
                radius: Settings.r(4)
                color: ctl.muted ? Colors.mutedFill : Colors.primary
            }
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: ctl.value * (slider.width - slider.knob)
            width: slider.knob
            height: slider.knob
            radius: Settings.r(slider.knob / 2)
            color: ctl.muted ? Colors.mutedFill : Colors.primary
            border.width: 2
            border.color: Colors.surfaceContainer
        }

        MouseArea {
            anchors.fill: parent
            preventStealing: true
            cursorShape: Qt.PointingHandCursor

            function setFrom(mx) {
                ctl.setValue((mx - slider.knob / 2) / (slider.width - slider.knob))
            }

            onPressed: mouse => setFrom(mouse.x)
            onPositionChanged: mouse => { if (pressed) setFrom(mouse.x) }
            onWheel: wheel => ctl.step(wheel.angleDelta.y > 0 ? 0.05 : -0.05)
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 32
        radius: Settings.r(999)
        color: ctl.muted ? Colors.primary
             : muteMouse.containsMouse ? Colors.surfaceContainerHighest
             : Colors.surfaceContainerHigh
        border.width: 1
        border.color: Colors.border

        Text {
            anchors.centerIn: parent
            text: ctl.muted ? ctl.mutedLabel : ctl.muteLabel
            color: ctl.muted ? Colors.textOnPrimary : Colors.text
            font.family: Settings.uiFontFamily
            font.pixelSize: 13
        }
        MouseArea {
            id: muteMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: ctl.toggleMute()
        }
    }
}
