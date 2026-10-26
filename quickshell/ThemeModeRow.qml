import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Тёмная или светлая тема. Выбор запускает matugen/apply-theme.sh: он пересчитывает палитру из текущих обоев
// и переключает Qt-приложения (через qt6ct), GTK-приложения и браузеры. Режим хранится в ~/.cache/theme-mode.
ColumnLayout {
    id: row
    spacing: 8

    readonly property string home: Quickshell.env("HOME")
    // Пока файла нет, действует тёмная тема (так её считает и сам скрипт)
    readonly property string mode: modeFile.text().trim() === "light" ? "light" : "dark"

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
        // apply-theme.sh уже переписал Colors.qml, но Quickshell сам его не перечитывает:
        // перезагружаем оболочку, чтобы бар и панель взяли новую палитру
        onExited: code => { if (code === 0) Quickshell.reload(false) }
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
            label: "Тёмная"
            selected: row.mode === "dark"
            onClicked: if (!applier.running && row.mode !== "dark") { applier.target = "dark"; applier.running = true }
        }
        BarChip {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            label: "Светлая"
            selected: row.mode === "light"
            onClicked: if (!applier.running && row.mode !== "light") { applier.target = "light"; applier.running = true }
        }
    }

    Text {
        Layout.fillWidth: true
        text: "Меняет палитру, Qt-приложения, GTK и браузеры. Открытые окна могут обновиться только после перезапуска."
        wrapMode: Text.WordWrap
        color: Colors.text
        opacity: 0.7
        font.family: Settings.uiFontFamily
        font.pixelSize: 13
    }
}
