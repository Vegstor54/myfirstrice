import Quickshell.Services.Mpris
import QtQuick
import ".."

// Модуль бара «Трек»: название играющего трека (MPRIS: Spotify, браузеры, mpv с mpv-mpris, VLC...).
// Клик ставит на паузу или продолжает, средняя кнопка — следующий трек.
// Грузится через Loader и в qmldir не регистрируется: если в этой сборке Quickshell нет
// модуля Quickshell.Services.Mpris, ломается только он, а не весь бар.
Rectangle {
    id: pill

    // Играющий плеер, иначе первый из списка (так же выбирает плеер MediaPlayer.qml)
    readonly property var player: {
        const ps = Mpris.players.values
        return ps.find(p => p.isPlaying) ?? ps[0] ?? null
    }
    readonly property string title: player !== null ? (player.trackTitle || "") : ""
    // Показывать модуль, только когда есть плеер с названием трека
    readonly property bool shown: player !== null && title !== ""
    readonly property bool playing: player !== null && player.isPlaying

    readonly property int maxTextWidth: 220

    height: Settings.barHeight - 8
    width: row.implicitWidth + 20
    radius: Settings.barRounded ? height / 2 : 0
    color: mouse.containsMouse ? Qt.alpha(Colors.text, 0.18) : Qt.alpha(Colors.text, 0.10)

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        // Нота; на паузе тусклая
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: ""
            color: Colors.text
            opacity: pill.playing ? 1 : 0.45
            font.family: "Symbols Nerd Font"
            font.pixelSize: Math.round(Settings.barHeight * 0.45)
        }

        Text {
            id: label
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, pill.maxTextWidth)
            text: pill.title
            elide: Text.ElideRight
            color: Colors.text
            opacity: pill.playing ? 1 : 0.6
            font.family: Settings.uiFontFamily
            font.pixelSize: Math.round(Settings.barHeight * 0.45)
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: ev => {
            if (pill.player === null) return
            if (ev.button === Qt.MiddleButton) {
                if (pill.player.canGoNext) pill.player.next()
            } else if (pill.player.canTogglePlaying) {
                pill.player.togglePlaying()
            }
        }
    }
}
