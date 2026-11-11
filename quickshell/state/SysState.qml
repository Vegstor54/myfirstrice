pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick
import ".."

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
    // Играющие приложения: потоки воспроизведения (media.class Stream/Output/Audio).
    // Запись (Stream/Input/Audio) сюда не входит. Если свойств узла нет, берём isSink:
    // поток воспроизведения для PipeWire — «приёмник» (как sink-input в pactl)
    function isPlayback(n) {
        const c = n.properties?.["media.class"]
        return c ? c === "Stream/Output/Audio" : n.isSink
    }
    readonly property var streams: Pipewire.nodes.values.filter(n => n.isStream && n.audio && isPlayback(n))

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

    // ---- Скорость сети ----
    // Загрузка (netDown) и отдача (netUp) в байтах в секунду по физическим сетевым картам.
    // Считается по разнице счётчиков (scripts/net-speed.sh) между двумя опросами раз в 2 секунды,
    // только пока модуль «Сеть» включён и показывает скорость (Settings.netStyle).
    property real netDown: 0
    property real netUp: 0
    property real lastRx: -1
    property real lastTx: -1
    property real lastNetTime: 0
    readonly property bool netSpeedNeeded: Settings.netStyle !== "icon" && Settings.moduleOn("network")

    // 1234 -> "1 kB/s", 1500000 -> "1.5 MB/s"
    function formatSpeed(bytesPerSec) {
        const kb = bytesPerSec / 1000
        if (Math.round(kb) < 1000) return Math.round(kb) + " kB/s"
        const mb = kb / 1000
        if (mb < 10) return mb.toFixed(1) + " MB/s"
        if (mb < 1000) return Math.round(mb) + " MB/s"
        return (mb / 1000).toFixed(1) + " GB/s"
    }

    readonly property string netSpeedText: "↓ " + formatSpeed(netDown) + "  ↑ " + formatSpeed(netUp)

    function parseNetSpeed(text) {
        const p = text.trim().split(/\s+/)
        if (p.length < 2) return
        const rx = parseFloat(p[0])
        const tx = parseFloat(p[1])
        if (isNaN(rx) || isNaN(tx)) return
        const now = Date.now()
        if (lastRx >= 0 && now > lastNetTime) {
            // Счётчики упали, если сменился набор сетевых карт: один такт показываем нули
            if (rx >= lastRx && tx >= lastTx) {
                const dt = (now - lastNetTime) / 1000
                netDown = (rx - lastRx) / dt
                netUp = (tx - lastTx) / dt
            } else {
                netDown = 0
                netUp = 0
            }
        }
        lastRx = rx
        lastTx = tx
        lastNetTime = now
    }

    Process {
        id: netSpeedReader
        command: [root.scripts + "/net-speed.sh"]
        stdout: StdioCollector {
            onStreamFinished: root.parseNetSpeed(text)
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: root.netSpeedNeeded
        triggeredOnStart: true
        onTriggered: if (!netSpeedReader.running) netSpeedReader.running = true
        // После паузы старые счётчики не годятся: скорость за долгий перерыв была бы средней
        onRunningChanged: if (!running) {
            root.lastRx = -1
            root.lastTx = -1
            root.netDown = 0
            root.netUp = 0
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
