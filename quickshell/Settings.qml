pragma Singleton
import Quickshell
import Quickshell.Io

Singleton {
    property alias barColor: adapter.barColor
    property alias uiFont: adapter.uiFont
    property alias monoFont: adapter.monoFont

    // Шрифт бара и панели: пока шрифт не выбран, берётся системный sans-serif из fontconfig
    readonly property string uiFontFamily: adapter.uiFont !== "" ? adapter.uiFont : "sans-serif"

    FileView {
        path: Quickshell.env("HOME") + "/.config/quickshell/settings.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: adapter
            property string barColor: "primaryContainer"
            property string uiFont: ""
            property string monoFont: "JetBrains Mono"
        }
    }
}
