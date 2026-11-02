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
    property real ramTotalGb: 0
    property real ramFreeGb: 0  // доступно (MemAvailable)
    property real ramCachedGb: 0
    property real swapUsedGb: 0
    property real swapTotalGb: 0
    property var cores: []      // загрузка каждого ядра, %
    property var load: [0, 0, 0] // load average за 1, 5, 15 минут
    property int cpuTemp: -1    // температура процессора, °C; -1 — датчик не найден

    readonly property bool hasTemp: cpuTemp >= 0
    readonly property string cpuTempText: cpuTemp + "°C"
    readonly property string cpuText: cpu + "%"
    readonly property string ramText: ramGb.toFixed(1) + "G"
    readonly property bool needed: Settings.moduleOn("cpu") || Settings.moduleOn("ram")

    // Прошлые счётчики процессора: загрузка считается по разнице между двумя опросами
    property real lastTotal: 0
    property real lastIdle: 0

    // Счётчики ядер с прошлого опроса: ключ «cpu0» -> [всего, простой]
    property var lastCore: ({})

    function parse(text) {
        const lines = text.split("\n")
        const coreNow = []
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
            } else if (p[0].indexOf("cpu") === 0) {
                const total = parseFloat(p[1])
                const idle = parseFloat(p[2])
                const prev = stats.lastCore[p[0]]
                let pct = 0
                if (prev && total > prev[0])
                    pct = Math.max(0, Math.min(100, Math.round((1 - (idle - prev[1]) / (total - prev[0])) * 100)))
                stats.lastCore[p[0]] = [total, idle]
                coreNow.push(pct)
            } else if (p[0] === "mem") {
                // mem занято всего доступно кэш своп-всего своп-свободно, в КиБ
                const gb = k => parseFloat(k) / 1048576
                stats.ramGb = gb(p[1])
                if (parseFloat(p[2]) > 0) stats.ramPct = Math.round(parseFloat(p[1]) / parseFloat(p[2]) * 100)
                stats.ramTotalGb = gb(p[2])
                stats.ramFreeGb = gb(p[3])
                stats.ramCachedGb = gb(p[4])
                stats.swapTotalGb = gb(p[5])
                stats.swapUsedGb = gb(p[5]) - gb(p[6])
            } else if (p[0] === "load") {
                stats.load = [parseFloat(p[1]), parseFloat(p[2]), parseFloat(p[3])]
            } else if (p[0] === "temp") {
                // temp <милли-градусы> от scripts/cpu-temp.sh; -1 — датчика нет
                const v = parseFloat(p[1])
                stats.cpuTemp = v >= 0 ? Math.round(v / 1000) : -1
            }
        }
        if (coreNow.length > 0) stats.cores = coreNow
    }

    // cpu и cpuN: сумма счётчиков и простой (idle + iowait); mem: занято, всего, доступно, кэш, своп (КиБ); load: loadavg;
    // temp: температура процессора в милли-градусах (cpu-temp.sh)
    Process {
        id: reader
        command: ["sh", "-c",
            "awk '/^cpu[0-9]* /{print $1, $2+$3+$4+$5+$6+$7+$8, $5+$6}' /proc/stat; " +
            "awk '/^MemTotal/{t=$2} /^MemAvailable/{a=$2} /^Cached/{c=$2} /^SwapTotal/{st=$2} /^SwapFree/{sf=$2} " +
            "END{print \"mem\", t-a, t, a, c, st, sf}' /proc/meminfo; " +
            "awk '{print \"load\", $1, $2, $3}' /proc/loadavg; " +
            "\"$HOME/.config/quickshell/scripts/cpu-temp.sh\""]
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
