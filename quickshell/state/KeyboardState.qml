pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import ".."

// Текущая раскладка клавиатуры для модуля бара «Раскладка».
// Стартовое значение берётся из `hyprctl devices -j` (active_keymap основной клавиатуры),
// дальше его обновляет событие Hyprland activelayout (приходит при каждом переключении, в том числе Alt+Shift).
Singleton {
    id: kb

    // Полное название от Hyprland, например «English (US)» или «Russian»
    property string layoutName: ""

    // Короткий код для бара: EN, RU. Пусто, пока раскладка неизвестна
    readonly property string code: shortCode(layoutName)

    readonly property var known: ({
        english: "EN", russian: "RU", ukrainian: "UA", belarusian: "BY", german: "DE", french: "FR",
        spanish: "ES", italian: "IT", portuguese: "PT", polish: "PL", czech: "CZ", turkish: "TR",
        japanese: "JP", chinese: "CN", korean: "KR", arabic: "AR", hebrew: "HE", greek: "GR",
        swedish: "SE", finnish: "FI", norwegian: "NO", danish: "DK", dutch: "NL", hungarian: "HU"
    })

    function shortCode(name) {
        if (name === "") return ""
        const first = name.trim().split(/[\s(]/)[0].toLowerCase()
        return known[first] ?? first.substring(0, 2).toUpperCase()
    }

    Process {
        command: ["hyprctl", "devices", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const keyboards = JSON.parse(text).keyboards ?? []
                    const main = keyboards.find(k => k.main) ?? keyboards[0]
                    if (main && main.active_keymap) kb.layoutName = main.active_keymap
                } catch (e) { console.log("keyboard layout parse error:", e) }
            }
        }
    }

    Connections {
        target: Hyprland

        // Данные события: «имя клавиатуры,название раскладки»
        function onRawEvent(event) {
            if (event.name !== "activelayout") return
            const parts = event.parse(2)
            if (parts.length > 1 && parts[1] !== "") kb.layoutName = parts[1]
        }
    }
}
