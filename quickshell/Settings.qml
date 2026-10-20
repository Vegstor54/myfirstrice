pragma Singleton
import Quickshell
import Quickshell.Io

Singleton {
    property alias barColor: adapter.barColor
    property alias uiFont: adapter.uiFont
    property alias monoFont: adapter.monoFont
    property alias barSize: adapter.barSize
    property alias showLogo: adapter.showLogo
    property alias wsMode: adapter.wsMode
    property alias barLeft: adapter.barLeft
    property alias barCenter: adapter.barCenter
    property alias barRight: adapter.barRight

    // Высота бара по выбранному размеру; остальные элементы бара считаются от неё
    readonly property int barHeight: barSize === "medium" ? 32 : barSize === "large" ? 40 : 26

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
            property string barSize: "small"
            property bool showLogo: true
            // Рабочие столы в баре: "used" — только используемые, "5" — 1–5, "10" — 1–10
            property string wsMode: "used"
            // Раскладка бара: ключи элементов через запятую по зонам (logo, workspaces, clock, indicators)
            property string barLeft: "logo,workspaces"
            property string barCenter: "clock"
            property string barRight: "indicators"
        }
    }
}
