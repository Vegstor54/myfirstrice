import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import ".."

// Режим темы: «Из обоев» (палитра по обоям), «Тёмная» и «Светлая» (фиксированные палитры). Выбор запускает
// matugen/apply-theme.sh: он пересчитывает палитру и переключает Qt-приложения (через qt6ct), GTK-приложения
// и браузеры. Режим хранится в ~/.cache/theme-mode.
ColumnLayout {
    id: row
    spacing: 8

    readonly property string home: Quickshell.env("HOME")
    // Пока файла нет, действует режим «Из обоев» (так его считает и сам скрипт)
    readonly property string mode: {
        const m = modeFile.text().trim()
        return (m === "dark" || m === "light") ? m : "wallpaper"
    }

    FileView {
        id: modeFile
        path: row.home + "/.cache/theme-mode"
        watchChanges: true
        onFileChanged: reload()
    }

    Process {
        id: applier
        property string target: ""
        command: ["bash", row.home + "/.config/matugen/apply-theme.sh", target]
        // apply-theme.sh переписывает Colors.qml; Quickshell следит за файлами конфига и сам перезагружается.
        // Явный Quickshell.reload(false) убран на пробу: если палитра не обновится, вернуть
    }

    function apply(target) {
        if (applier.running || row.mode === target) return
        applier.target = target
        applier.running = true
    }

    Text {
        text: "Тема"
        color: Colors.text
        font.family: Settings.uiFontFamily
        font.pixelSize: 14
        font.bold: true
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        BarChip {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            label: "Из обоев"
            selected: row.mode === "wallpaper"
            onClicked: row.apply("wallpaper")
        }
        BarChip {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            label: "Тёмная"
            selected: row.mode === "dark"
            onClicked: row.apply("dark")
        }
        BarChip {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            label: "Светлая"
            selected: row.mode === "light"
            onClicked: row.apply("light")
        }
    }

    Text {
        Layout.fillWidth: true
        text: "«Из обоев» берёт цвета с обоев, «Тёмная» — чёрная с белым, «Светлая» — белая с чёрным. Меняет палитру, Qt-приложения, GTK и браузеры. Открытые окна могут обновиться только после перезапуска."
        wrapMode: Text.WordWrap
        color: Colors.text
        opacity: 0.7
        font.family: Settings.uiFontFamily
        font.pixelSize: 13
    }
}
