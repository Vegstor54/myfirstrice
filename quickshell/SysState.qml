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

    // ---- Микшер: громкость любого узла и приложения ----
    // Играющие приложения: потоки воспроизведения (сами выдают звук, поэтому не isSink)
    readonly property var streams: Pipewire.nodes.values.filter(n => n.isStream && !n.isSink && n.audio)

    function appName(node) {
        return node.properties?.["application.name"] || node.description || node.nickname || node.name
    }

    function setNodeVolume(node, v) {
        if (node?.audio) node.audio.volume = Math.max(0, Math.min(1, v))
    }

    function toggleNodeMute(node) {
        if (node?.audio) node.audio.muted = !node.audio.muted
    }

    // Переносит звук приложения на другое устройство вывода (scripts/move-stream.sh через pactl)
    Process {
        id: mover
        property string nodeId: ""
        property string serial: ""
        property string sinkName: ""
        command: [root.scripts + "/move-stream.sh", nodeId, serial, sinkName]
        onExited: code => {
            if (code === 2) console.log("mixer: не найден pactl (пакет libpulse), перенос звука невозможен")
            else if (code === 3) console.log("mixer: поток приложения не найден в pactl list sink-inputs")
            else if (code !== 0) console.log("mixer: перенос звука завершился с кодом", code)
        }
    }

    function moveStream(stream, sink) {
        if (mover.running || !stream || !sink) return
        mover.nodeId = String(stream.id)
        mover.serial = stream.properties?.["object.serial"] ?? ""
        mover.sinkName = sink.name
        mover.running = true
    }

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
