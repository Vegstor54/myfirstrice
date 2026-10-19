import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick

// Правая часть бара: сеть, звук, уведомления.
//  - сеть: значок показывает тип подключения, клик открывает программу управления сетью
//  - звук: колесо мыши меняет громкость, клик включает и выключает звук
//  - уведомления: пока заглушка, панели уведомлений ещё нет
// Значки — глифы Nerd Font (Symbols Nerd Font), как у кнопки с логотипом.
Row {
    id: root
    spacing: 4

    readonly property string scripts: Quickshell.env("HOME") + "/.config/quickshell/scripts"

    // ---- Звук (PipeWire) ----
    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [root.sink] }

    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false

    function changeVolume(delta) {
        if (!sink?.audio) return
        sink.audio.volume = Math.max(0, Math.min(1, volume + delta))
    }

    function toggleMute() {
        if (sink?.audio) sink.audio.muted = !sink.audio.muted
    }

    // ---- Сеть ----
    // "ethernet", "wifi" или "none"; обновляется раз в 5 секунд
    property string net: "none"

    Process {
        id: netStatus
        command: [root.scripts + "/net-status.sh"]
        stdout: StdioCollector {
            onStreamFinished: root.net = text.trim()
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!netStatus.running) netStatus.running = true
    }

    Process {
        id: netOpen
        command: [root.scripts + "/open-network.sh"]
        onExited: code => {
            if (code === 2) console.log("network: не найдена программа управления сетью (nm-connection-editor, impala, nmtui)")
        }
    }

    // ---- Кнопка бара: значок и необязательная подпись ----
    component IndicatorButton: Rectangle {
        id: btn
        property string glyph: ""
        property string label: ""
        property real dim: 1
        property bool clickable: true
        signal clicked()
        signal scrolled(int delta)

        height: Settings.barHeight - 8
        width: Math.max(height, content.implicitWidth + 12)
        radius: height / 2
        color: clickable && area.containsMouse ? Qt.rgba(1, 1, 1, 0.18) : "transparent"

        Row {
            id: content
            anchors.centerIn: parent
            spacing: 4
            opacity: btn.dim

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: btn.glyph
                color: Colors.text
                font.family: "Symbols Nerd Font"
                font.pixelSize: Math.round(Settings.barHeight * 0.45)
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: btn.label !== ""
                text: btn.label
                color: Colors.text
                font.family: Settings.uiFontFamily
                font.pixelSize: Math.round(Settings.barHeight * 0.4)
            }
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: btn.clickable
            cursorShape: btn.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (btn.clickable) btn.clicked()
            onWheel: wheel => btn.scrolled(wheel.angleDelta.y)
        }
    }

    // Сеть:  — wifi,  — проводное подключение; без сети значок тусклый
    IndicatorButton {
        glyph: root.net === "ethernet" ? "" : ""
        dim: root.net === "none" ? 0.35 : 1
        onClicked: netOpen.running = true
    }

    // Звук:  — громко,  — тихо,  — выключено
    IndicatorButton {
        glyph: root.muted || root.volume <= 0 ? "" : root.volume < 0.5 ? "" : ""
        label: Math.round(root.volume * 100) + "%"
        dim: root.muted ? 0.4 : 1
        onClicked: root.toggleMute()
        onScrolled: delta => root.changeVolume(delta > 0 ? 0.05 : -0.05)
    }

    // Уведомления:  — колокольчик. Панели уведомлений пока нет, поэтому кнопка без действия
    IndicatorButton {
        glyph: ""
        clickable: false
    }
}
