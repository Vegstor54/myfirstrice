import QtQuick
import QtQuick.Layouts

// Вертикальный ползунок громкости колонок: сверху максимум, снизу ноль.
// Тянуть или кликать; колесо меняет на 5%; кнопка внизу включает и выключает звук.
ColumnLayout {
    id: ctl
    spacing: 10

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: Math.round(SysState.volume * 100) + "%"
        color: Colors.text
        font.family: Settings.uiFontFamily
        font.pixelSize: 13
    }

    Item {
        id: track
        Layout.alignment: Qt.AlignHCenter
        Layout.fillHeight: true
        Layout.preferredWidth: 36

        readonly property real knob: 24

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 12
            height: parent.height
            radius: Settings.r(6)
            color: Colors.surfaceContainerHighest
            border.width: 1
            border.color: Colors.border

            // Заливка растёт снизу вверх
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: SysState.volume * (track.height - track.knob) + track.knob / 2
                radius: Settings.r(6)
                color: SysState.muted ? Colors.mutedFill : Colors.primary
            }
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: (1 - SysState.volume) * (track.height - track.knob)
            width: track.knob
            height: track.knob
            radius: Settings.r(track.knob / 2)
            color: SysState.muted ? Colors.mutedFill : Colors.primary
            border.width: 2
            border.color: Colors.surfaceContainer
        }

        MouseArea {
            anchors.fill: parent
            preventStealing: true
            cursorShape: Qt.PointingHandCursor

            function setFrom(my) {
                SysState.setVolume(1 - (my - track.knob / 2) / (track.height - track.knob))
            }

            onPressed: mouse => setFrom(mouse.y)
            onPositionChanged: mouse => { if (pressed) setFrom(mouse.y) }
            onWheel: wheel => SysState.changeVolume(wheel.angleDelta.y > 0 ? 0.05 : -0.05)
        }
    }

    Rectangle {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: 36
        Layout.preferredHeight: 36
        radius: Settings.r(18)
        color: SysState.muted ? Colors.primary
             : muteMouse.containsMouse ? Colors.surfaceContainerHighest
             : Colors.surfaceContainerHigh
        border.width: 1
        border.color: Colors.border

        // Значки звука — глифы Nerd Font: громко, тихо, выключено
        Text {
            anchors.centerIn: parent
            text: SysState.muted || SysState.volume <= 0 ? "" : SysState.volume < 0.5 ? "" : ""
            color: SysState.muted ? Colors.textOnPrimary : Colors.text
            font.family: "Symbols Nerd Font"
            font.pixelSize: 16
        }
        MouseArea {
            id: muteMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: SysState.toggleMute()
        }
    }
}
