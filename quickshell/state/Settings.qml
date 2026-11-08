pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Singleton {
    property alias barColor: adapter.barColor
    property alias uiFont: adapter.uiFont
    property alias monoFont: adapter.monoFont
    property alias barSize: adapter.barSize
    property alias showLogo: adapter.showLogo
    property alias barRounded: adapter.barRounded
    property alias barStyle: adapter.barStyle
    property alias barAttached: adapter.barAttached
    property alias statStyle: adapter.statStyle
    property alias cpuStyle: adapter.cpuStyle
    property alias ramStyle: adapter.ramStyle
    property alias cpuLabel: adapter.cpuLabel
    property alias ramLabel: adapter.ramLabel
    property alias cpuShowTemp: adapter.cpuShowTemp
    property alias ramValue: adapter.ramValue
    property alias uiRounded: adapter.uiRounded
    property alias wsMode: adapter.wsMode
    property alias barLeft: adapter.barLeft
    property alias barCenter: adapter.barCenter
    property alias barRight: adapter.barRight
    property alias barOff: adapter.barOff
    property alias indGroups: adapter.indGroups
    property alias dnd: adapter.dnd
    property alias clockSeconds: adapter.clockSeconds
    property alias clock24: adapter.clock24
    property alias clockDate: adapter.clockDate
    property alias clockCustom: adapter.clockCustom

    // Формат часов в баре (Qt.formatDateTime): свой, если задан, иначе из настроек часов
    readonly property string clockFormat: {
        if (clockCustom !== "") return clockCustom
        const time = clock24 ? (clockSeconds ? "HH:mm:ss" : "HH:mm")
                             : (clockSeconds ? "h:mm:ss AP" : "h:mm AP")
        const date = clockDate === "short" ? "d MMM"
                   : clockDate === "weekday" ? "ddd, d MMM"
                   : clockDate === "numeric" ? "ddd dd.MM"
                   : ""
        return date !== "" ? date + "  " + time : time
    }
    // Нужно ли часам тикать каждую секунду
    readonly property bool clockTicksSeconds: clockCustom !== "" ? clockCustom.indexOf("s") >= 0 : clockSeconds

    // Отступ бара от боковых краёв экрана (его используют shell.qml и QuickMenu)
    readonly property int barSideMargin: 16
    // Стиль «острова»: у бара нет общей подложки, у каждой зоны (слева, по центру, справа) своя «таблетка»
    readonly property bool islands: barStyle === "islands"
    // Положение самого бара: скруглённый и «острова» «плавают» с отступами, прямой занимает всю верхнюю кромку экрана
    // Отдельная кнопка «К краям экрана» (barAttached) прижимает сплошной бар к краям при любой форме;
    // в стиле «острова» она не действует: у островов нет общей подложки, которую можно прижать
    readonly property bool attached: barAttached && !islands
    readonly property int barEdge: attached ? 0 : (barRounded || islands ? barSideMargin : 0)
    readonly property int barTop: attached ? 0 : (barRounded || islands ? 8 : 0)

    // Заливка кнопок, плиток и строк вместо обводки: оттенок от цвета текста,
    // поэтому в тёмной теме светлее фона карточки, в светлой темнее
    // Тёмный текст на светлом фоне даёт слабый контраст, поэтому в светлой теме заливка сильнее
    readonly property bool lightTheme: Colors.surface.hslLightness > 0.5
    readonly property color fill: Qt.tint(Colors.surfaceContainer, Qt.alpha(Colors.text, lightTheme ? 0.16 : 0.10))
    // Выбранная строка или пункт под курсором: нейтральная, сильнее наведения, без акцентного цвета
    readonly property color fillActive: Qt.tint(Colors.surfaceContainer, Qt.alpha(Colors.text, lightTheme ? 0.32 : 0.24))
    readonly property color fillHover: Qt.tint(Colors.surfaceContainer, Qt.alpha(Colors.text, lightTheme ? 0.25 : 0.17))

    // Форма интерфейса (панель, меню, уведомления, плитки, кнопки, ползунки) не зависит от формы бара.
    // Радиус любого такого элемента — Settings.r(радиус), в прямом режиме он 0. Форму самого бара задаёт barRounded.
    function r(radius) { return uiRounded ? radius : 0 }

    // Включён ли модуль бара (выключенные перечислены в barOff)
    function moduleOn(key) { return barOff.split(",").indexOf(key) < 0 }
    function setModule(key, on) {
        const list = barOff.split(",").filter(x => x !== "" && x !== key)
        if (!on) list.push(key)
        barOff = list.join(",")
    }

    // Вид показателя CPU или памяти: "text", "gauge" (кольцо) или "bar" (сегментная полоска).
    // Свой выбор модуля (cpuStyle, ramStyle), а пока он пуст — общий statStyle, как было до страниц настроек модулей
    function statMode(kind) {
        const own = kind === "ram" ? ramStyle : cpuStyle
        return own !== "" ? own : statStyle
    }
    function setStatMode(kind, mode) {
        if (kind === "ram") ramStyle = mode
        else cpuStyle = mode
    }
    // Что стоит перед значением в видах «Текст» и «Полоса»: "icon" — значок, "text" — подпись (cpu, ram), "none" — ничего
    function statLabel(kind) { return kind === "ram" ? ramLabel : cpuLabel }
    function setStatLabel(kind, label) {
        if (kind === "ram") ramLabel = label
        else cpuLabel = label
    }

    // Высота бара по выбранному размеру; остальные элементы бара считаются от неё
    readonly property int barHeight: barSize === "medium" ? 32 : barSize === "large" ? 40 : 26

    // Шрифт бара и панели: пока шрифт не выбран, берётся системный sans-serif из fontconfig
    readonly property string uiFontFamily: adapter.uiFont !== "" ? adapter.uiFont : "sans-serif"

    FileView {
        path: Quickshell.env("HOME") + "/.config/quickshell/settings.json"
        // Читаем файл сразу, до создания бара: иначе первые кадры идут со значениями по умолчанию
        // (скруглённый бар с отступами), и только потом подтягиваются сохранённые
        blockLoading: true
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
            // Стиль бара: "solid" — одна общая подложка, "islands" — отдельная «таблетка» на каждую зону
            property string barStyle: "solid"
            // Сплошной бар прижат к краям экрана (без отступов), независимо от скругления элементов
            property bool barAttached: false
            // Вид CPU и памяти в баре по умолчанию: "text" — значок и значение, "gauge" — кольцо-«спидометр» без стрелки,
            // "bar" — сегментная полоска. Пока у модуля нет своего выбора (cpuStyle, ramStyle), берётся этот
            property string statStyle: "text"
            // Свой вид модуля: "" — как statStyle, иначе "text", "gauge" или "bar"
            property string cpuStyle: ""
            property string ramStyle: ""
            // Подпись перед значением в видах «Текст» и «Полоса»: "icon", "text" или "none"
            property string cpuLabel: "icon"
            property string ramLabel: "icon"
            // Температура рядом с загрузкой CPU (показывается, пока датчик найден)
            property bool cpuShowTemp: true
            // Значение памяти: "gb" — занято в ГиБ, "pct" — процент от всей
            property string ramValue: "gb"
            // Форма остального интерфейса: true — скруглённый, false — прямой (не зависит от формы бара)
            property bool uiRounded: true
            // Рабочие столы в баре: "used" — только используемые, "5" — 1–5, "10" — 1–10
            property string wsMode: "used"
            // Раскладка бара: ключи элементов через запятую по зонам (logo, workspaces, clock, media, cava, tray, network, bluetooth, sound, notifications, ram, cpu, layout, power)
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
            // Часы в баре: секунды, 24-часовой формат, дата ("none", "short", "weekday", "numeric"), свой формат (пусто — не используется)
            property bool clockSeconds: false
            property bool clock24: true
            property string clockDate: "none"
            property string clockCustom: ""
        }
    }
}
