import Quickshell
import Quickshell.Io
import QtQuick

// Модуль бара «Cava»: столбики-эквалайзер от звука, который сейчас играет; столбики растут снизу вверх.
// cava запускается с cava.conf (вывод цифрами в stdout, 12 столбиков, 30 кадров в секунду),
// каждая строка вывода — один кадр вида «12;45;80;...».
// Показывается, только если cava установлена (`pacman -S cava`); пока модуль выключен, процесс не работает.
// Грузится через Loader и в qmldir не регистрируется: если что-то пойдёт не так, ломается только он.
Rectangle {
    id: pill

    // Число столбиков должно совпадать с bars в cava.conf
    readonly property int barCount: 12
    readonly property int barWidth: Math.max(2, Math.round(Settings.barHeight * 0.1))
    readonly property int maxBarHeight: pill.height - 6

    property bool available: false
    property var values: []

    readonly property bool shown: available

    height: Settings.barHeight - 8
    width: row.implicitWidth + 20
    radius: Settings.barRounded ? height / 2 : 0
    color: Qt.rgba(1, 1, 1, 0.10)

    // Есть ли cava в системе
    Process {
        command: ["sh", "-c", "command -v cava"]
        running: true
        onExited: code => pill.available = code === 0
    }

    // Сам cava: работает, только пока модуль включён и cava установлена
    Process {
        id: cava
        command: ["cava", "-p", Quickshell.env("HOME") + "/.config/quickshell/cava.conf"]
        running: pill.available && Settings.moduleOn("cava")
        stdout: SplitParser {
            onRead: line => {
                const v = line.split(";").filter(s => s !== "").map(s => Number(s))
                if (v.length > 0) pill.values = v
            }
        }
        // Выключили модуль или cava закрылась: столбики опускаются
        onRunningChanged: if (!running) pill.values = []
    }

    // Ряд фиксированной высоты: столбики стоят на общем нижнем крае и тянутся вверх
    Row {
        id: row
        anchors.centerIn: parent
        height: pill.maxBarHeight
        spacing: Math.max(1, Math.round(pill.barWidth / 2))

        Repeater {
            model: pill.barCount

            Item {
                required property int index
                readonly property real level: Math.min(1, Math.max(0, (pill.values[index] ?? 0) / 100))

                width: pill.barWidth
                height: row.height

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: Math.max(2, Math.round(parent.level * pill.maxBarHeight))
                    radius: Settings.barRounded ? width / 2 : 0
                    color: Colors.text
                    opacity: 0.45 + 0.55 * parent.level
                }
            }
        }
    }
}
