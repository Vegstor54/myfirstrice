import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts

// Плеер: обложка, название, исполнитель, шкала времени и кнопки. Работает с любым плеером,
// который говорит по MPRIS (Spotify, браузеры, mpv, VLC и т.д.).
// Грузится через Loader и в qmldir не регистрируется: если в этой сборке Quickshell нет
// модуля Quickshell.Services.Mpris, ломается только плеер, а не всё меню.
ColumnLayout {
    id: root
    spacing: 8

    // Играющий плеер, иначе первый из списка
    readonly property var player: {
        const ps = Mpris.players.values
        return ps.find(p => p.isPlaying) ?? ps[0] ?? null
    }
    readonly property bool playing: player !== null && player.isPlaying
    readonly property real length: player !== null && player.lengthSupported ? player.length : 0
    readonly property real position: player !== null && player.positionSupported ? player.position : 0

    // Позиция сама не обновляется: пока играет, просим перечитывать её каждый кадр
    FrameAnimation {
        running: root.playing && root.player.positionSupported
        onTriggered: root.player.positionChanged()
    }

    function fmt(sec) {
        const s = Math.max(0, Math.floor(sec))
        const h = Math.floor(s / 3600)
        const m = Math.floor((s % 3600) / 60)
        const r = s % 60
        const mm = h > 0 ? String(m).padStart(2, "0") : String(m)
        return (h > 0 ? h + ":" : "") + mm + ":" + String(r).padStart(2, "0")
    }

    // Обложка со скруглением
    Item {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: 200
        Layout.preferredHeight: 200

        Rectangle {
            anchors.fill: parent
            radius: Settings.r(16)
            color: Colors.surfaceContainerHigh
            border.width: 1
            border.color: Colors.border
        }

        Image {
            id: art
            anchors.fill: parent
            visible: false
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: 400
            source: root.player?.trackArtUrl ?? ""
        }

        Rectangle {
            id: artMask
            anchors.fill: parent
            radius: Settings.r(16)
            visible: false
            layer.enabled: true
        }

        MultiEffect {
            anchors.fill: parent
            source: art
            maskEnabled: true
            maskSource: artMask
            visible: art.status === Image.Ready
        }

        // Нет обложки: значок ноты
        Text {
            anchors.centerIn: parent
            visible: art.status !== Image.Ready
            text: ""
            color: Colors.text
            opacity: 0.35
            font.family: "Symbols Nerd Font"
            font.pixelSize: 56
        }
    }

    Text {
        Layout.fillWidth: true
        text: root.player === null ? "Ничего не играет" : (root.player.trackTitle || "Без названия")
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        color: Colors.text
        font.family: Settings.uiFontFamily
        font.pixelSize: 15
        font.bold: true
    }

    Text {
        Layout.fillWidth: true
        visible: text !== ""
        text: root.player?.trackArtist ?? ""
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        color: Colors.text
        opacity: 0.7
        font.family: Settings.uiFontFamily
        font.pixelSize: 12
    }

    // Шкала времени: клик перематывает, если плеер это умеет
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2
        visible: root.player !== null

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 14

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 6
                radius: Settings.r(3)
                color: Colors.surfaceContainerHighest
                border.width: 1
                border.color: Colors.border

                Rectangle {
                    width: root.length > 0 ? parent.width * Math.min(1, root.position / root.length) : 0
                    height: parent.height
                    radius: Settings.r(3)
                    color: Colors.primary
                }
            }

            MouseArea {
                anchors.fill: parent
                enabled: root.player !== null && root.player.canSeek && root.length > 0
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: mouse => root.player.position = Math.max(0, Math.min(1, mouse.x / width)) * root.length
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: root.fmt(root.position)
                color: Colors.text
                opacity: 0.7
                font.family: Settings.uiFontFamily
                font.pixelSize: 11
            }
            Item { Layout.fillWidth: true }
            Text {
                text: root.length > 0 ? root.fmt(root.length) : ""
                color: Colors.text
                opacity: 0.7
                font.family: Settings.uiFontFamily
                font.pixelSize: 11
            }
        }
    }

    // Кнопки: назад, пауза и пуск, вперёд (недоступные приглушены)
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 12

        Repeater {
            model: [
                { glyph: "", kind: "prev" },
                { glyph: "", kind: "toggle" },
                { glyph: "", kind: "next" }
            ]

            Rectangle {
                id: btn
                required property var modelData
                readonly property bool main: modelData.kind === "toggle"
                readonly property bool usable: root.player !== null && (
                    modelData.kind === "prev" ? root.player.canGoPrevious
                  : modelData.kind === "next" ? root.player.canGoNext
                  : root.player.canTogglePlaying)

                Layout.preferredWidth: main ? 44 : 36
                Layout.preferredHeight: Layout.preferredWidth
                radius: Settings.r(width / 2)
                opacity: usable ? 1 : 0.35
                color: main ? Colors.primary
                     : btnMouse.containsMouse && usable ? Colors.surfaceContainerHighest
                     : Colors.surfaceContainerHigh
                border.width: 1
                border.color: Colors.border

                Text {
                    anchors.centerIn: parent
                    text: btn.main ? (root.playing ? "" : "") : btn.modelData.glyph
                    color: btn.main ? Colors.textOnPrimary : Colors.text
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: btn.main ? 18 : 14
                }
                MouseArea {
                    id: btnMouse
                    anchors.fill: parent
                    enabled: btn.usable
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (btn.modelData.kind === "prev") root.player.previous()
                        else if (btn.modelData.kind === "next") root.player.next()
                        else root.player.togglePlaying()
                    }
                }
            }
        }
    }

    Item { Layout.fillHeight: true }
}
