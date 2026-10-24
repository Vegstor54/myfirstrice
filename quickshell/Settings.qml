pragma Singleton
import Quickshell
import Quickshell.Io

Singleton {
    property alias barColor: adapter.barColor
    property alias uiFont: adapter.uiFont
    property alias monoFont: adapter.monoFont
    property alias barSize: adapter.barSize
    property alias showLogo: adapter.showLogo
    property alias barRounded: adapter.barRounded
    property alias wsMode: adapter.wsMode
    property alias barLeft: adapter.barLeft
    property alias barCenter: adapter.barCenter
    property alias barRight: adapter.barRight
    property alias barOff: adapter.barOff
    property alias indGroups: adapter.indGroups
    property alias dnd: adapter.dnd

    // Отступ бара от боковых краёв экрана (его используют shell.qml и QuickMenu)
    readonly property int barSideMargin: 16
    // Положение самого бара: скруглённый «плавает» с отступами, прямой занимает всю верхнюю кромку экрана
    readonly property int barEdge: barRounded ? barSideMargin : 0
    readonly property int barTop: barRounded ? 8 : 0

    // Включён ли модуль бара (выключенные перечислены в barOff)
    function moduleOn(key) { return barOff.split(",").indexOf(key) < 0 }
    function setModule(key, on) {
        const list = barOff.split(",").filter(x => x !== "" && x !== key)
        if (!on) list.push(key)
        barOff = list.join(",")
    }

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
            // Форма бара: true — скруглённый «таблеткой» с отступами, false — прямой и во всю ширину экрана
            property bool barRounded: true
            // Рабочие столы в баре: "used" — только используемые, "5" — 1–5, "10" — 1–10
            property string wsMode: "used"
            // Раскладка бара: ключи элементов через запятую по зонам (logo, workspaces, clock, media, cava, tray, network, bluetooth, sound, notifications)
            property string barLeft: "logo,workspaces"
            property string barCenter: "clock"
            property string barRight: "network,bluetooth,sound,notifications"
            // Выключенные модули бара через запятую (workspaces, clock, media, cava, tray, network, bluetooth, sound, notifications)
            property string barOff: ""
            // Группы значков справа: группы через "|", модули в группе через ",".
            // Модули идут в порядке network, bluetooth, sound, notifications; группа — одна «таблетка»
            property string indGroups: "network,bluetooth,sound,notifications"
            // Режим «не беспокоить»: всплывающие уведомления не показываются (срочные показываются)
            property bool dnd: false
        }
    }
}
