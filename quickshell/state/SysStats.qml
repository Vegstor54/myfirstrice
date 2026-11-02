pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import ".."

// Загрузка процессора и занятая память для модулей бара «CPU» и «Память» (BarStat.qml).
// Раз в две секунды читает /proc/stat и /proc/meminfo; пока оба модуля выключены, опроса нет.
Singleton {
    id: stats

    property int cpu: 0         // загрузка процессора, %
    property real ramGb: 0      // занято памяти без кэша, ГиБ
    property int ramPct: 0      // занято памяти, % от всей

    readonly property string cpuText: cpu + "%"
    readonly property string ramText: ramGb.toFixed(1) + "G"
    readonly property bool needed: Settings.moduleOn("cpu") || Settings.moduleOn("ram")

    // Прошлые счётчики процессора: загрузка считается по разнице между двумя опросами
    property real lastTotal: 0
    property real lastIdle: 0

    function parse(text) {
        const lines = text.split("\n")
        for (let i = 0; i < lines.length; i++) {
            const p = lines[i].trim().split(/\s+/)
            if (p[0] === "cpu") {
                const total = parseFloat(p[1])
                const idle = parseFloat(p[2])
                if (stats.lastTotal > 0 && total > stats.lastTotal) {
                    const busy = 1 - (idle - stats.lastIdle) / (total - stats.lastTotal)
                    stats.cpu = Math.max(0, Math.min(100, Math.round(busy * 100)))
                }
                stats.lastTotal = total
                stats.lastIdle = idle
            } else if (p[0] === "mem") {
                stats.ramGb = parseFloat(p[1]) / 1048576
                if (parseFloat(p[2]) > 0) stats.ramPct = Math.round(parseFloat(p[1]) / parseFloat(p[2]) * 100)
            }
        }
    }

    // cpu: сумма счётчиков и простой (idle + iowait); mem: занято = всего − доступно и всего, в КиБ
    Process {
        id: reader
        command: ["sh", "-c",
            "awk '/^cpu /{print \"cpu\", $2+$3+$4+$5+$6+$7+$8, $5+$6}' /proc/stat; " +
            "awk '/^MemTotal/{t=$2} /^MemAvailable/{a=$2} END{print \"mem\", t-a, t}' /proc/meminfo"]
        stdout: StdioCollector {
            onStreamFinished: stats.parse(text)
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: stats.needed
        triggeredOnStart: true
        onTriggered: if (!reader.running) reader.running = true
    }
}
