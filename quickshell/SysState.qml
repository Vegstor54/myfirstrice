pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick

// Общее состояние для бара и выезжающего меню: звук, устройства вывода и микрофон (PipeWire), сеть.
// Один экземпляр на всю оболочку, поэтому сеть опрашивается один раз, а не на каждом мониторе.
Singleton {
    id: root

    readonly property string scripts: Quickshell.env("HOME") + "/.config/quickshell/scripts"

    // ---- Звук ----
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    PwObjectTracker { objects: [root.sink, root.source] }

    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false

    function setVolume(v) {
        if (sink?.audio) sink.audio.volume = Math.max(0, Math.min(1, v))
    }

    function changeVolume(delta) { setVolume(volume + delta) }

    function toggleMute() {
        if (sink?.audio) sink.audio.muted = !sink.audio.muted
    }

    // ---- Устройства вывода ----
    // Отслеживаем все узлы PipeWire, иначе у них не будет данных об аудио
    PwObjectTracker { objects: Pipewire.nodes.values }

    // Аудио-выходы (колонки, наушники, HDMI), без потоков приложений
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)

    function sinkName(node) { return node.description || node.nickname || node.name }

    // Делает устройство выходом по умолчанию
    function setDefaultSink(node) { Pipewire.preferredDefaultAudioSink = node }

    // ---- Микрофон ----
    readonly property real micVolume: source?.audio?.volume ?? 0
    readonly property bool micMuted: source?.audio?.muted ?? false

    function setMicVolume(v) {
        if (source?.audio) source.audio.volume = Math.max(0, Math.min(1, v))
    }

    function changeMicVolume(delta) { setMicVolume(micVolume + delta) }

    function toggleMicMute() {
        if (source?.audio) source.audio.muted = !source.audio.muted
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

    // ---- Bluetooth: можно ли пользоваться ----
    // Значок и вкладка Bluetooth скрыты, пока не установлен пакет bluez (демон bluetoothd)
    // или нет адаптера. Проверяет scripts/bt-present.sh
    property bool hasBluetooth: false

    Process {
        id: btCheck
        command: [root.scripts + "/bt-present.sh"]
        stdout: StdioCollector {
            onStreamFinished: root.hasBluetooth = text.trim() === "yes"
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!netStatus.running) netStatus.running = true
            if (!btCheck.running) btCheck.running = true
        }
    }

    Process {
        id: netOpen
        command: [root.scripts + "/open-network.sh"]
        onExited: code => {
            if (code === 2) console.log("network: не найдена программа управления сетью (nm-connection-editor, impala, nmtui)")
        }
    }

    function openNetwork() { netOpen.running = true }
}
