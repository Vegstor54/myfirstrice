import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import ".."
import "DisplaysLogic.js" as Logic

// Дисплеи: превью расположения мониторов (перетаскивание с притягиванием к краям),
// по каждому монитору разрешение, частота, масштаб, поворот, включение и «основной при старте».
// Список берётся из `hyprctl monitors all -j`. «Применить» переписывает hypr/conf/monitors.lua
// (set-monitors.sh) и перезагружает конфиг Hyprland. Вся логика расчётов — в DisplaysLogic.js.
Item {
    id: tab

    signal closeRequested()

    readonly property string scripts: Quickshell.env("HOME") + "/.config/quickshell/scripts"

    // Модель всегда заменяется целиком (commit), а Repeater'ы ниже работают по числу мониторов
    // (model: mons.length), иначе каждое изменение пересоздавало бы строки и рвало перетаскивание
    property var mons: []
    property string primary: ""
    property int selected: -1
    property bool dirty: false
    property bool dragging: false
    property string status: ""
    property bool failed: false
    property bool readFailed: false

    // Параметры превью (масштаб и смещение); пока монитор тянут, не пересчитываются
    property real viewK: 0.05
    property real viewOx: 0
    property real viewOy: 0

    readonly property var overlaps: Logic.overlapPairs(mons)
    readonly property int enabledCount: mons.filter(m => m.enabled).length
    readonly property bool canApply: dirty && overlaps.length === 0 && !applier.running

    // Пресеты раскладки: базовый монитор (встроенный или основной при старте)
    // и пресет, на который сейчас похоже состояние мониторов
    readonly property int baseIdx: Logic.baseIndex(mons, primary)
    readonly property var presets: Logic.presetList(mons)
    readonly property string activePreset: Logic.detectPreset(mons, baseIdx)
    // Цвета мониторов в превью и значках пресетов (по кругу, как синий и оранжевый на макете)
    readonly property var monColors: [Colors.primary, Colors.tertiary, Colors.secondary, Colors.primaryContainer]

    function clone() { return tab.mons.map(m => Object.assign({}, m)) }

    function recalc() {
        const v = Logic.viewParams(tab.mons, preview.width, preview.height)
        tab.viewK = v.k
        tab.viewOx = v.ox
        tab.viewOy = v.oy
    }

    function commit(arr) {
        tab.mons = arr
        tab.dirty = true
        tab.status = ""
        tab.failed = false
        tab.readFailed = false
        if (!tab.dragging) tab.recalc()
    }

    function load(text) {
        let list
        try { list = JSON.parse(text) }
        catch (e) {
            tab.status = "Не удалось прочитать список мониторов"
            tab.failed = true
            tab.readFailed = true
            return
        }
        // Сообщение об ошибке чтения исчезает, когда список удалось прочитать; «Применено» и ошибки применения остаются
        if (tab.readFailed) {
            tab.readFailed = false
            tab.status = ""
            tab.failed = false
        }
        const keep = tab.selected >= 0 && tab.selected < tab.mons.length ? tab.mons[tab.selected].name : ""
        tab.mons = Logic.fromHyprctl(list)
        tab.selected = tab.mons.findIndex(m => m.name === keep)
        tab.dirty = false
        tab.recalc()
    }

    function moveTo(i, x, y) {
        const arr = tab.clone()
        const p = Logic.snap(arr, i, Math.round(x), Math.round(y), 14 / tab.viewK)
        arr[i].x = p.x
        arr[i].y = p.y
        tab.commit(arr)
    }

    // Меняет режим, масштаб или поворот монитора и подвигает соседей, чтобы не было наложения и щели
    function change(i, props) {
        const arr = tab.clone()
        const old = Logic.logicalSize(arr[i])
        Object.assign(arr[i], props)
        Logic.resized(arr, i, old)
        tab.commit(arr)
    }

    function pickResolution(i, w, h) {
        const hz = Logic.closestHz(Logic.refreshes(tab.mons[i].modes, w, h), tab.mons[i].hz)
        tab.change(i, { w: w, h: h, hz: hz })
    }

    function setEnabled(i, on) {
        if (!on && tab.enabledCount <= 1) {
            tab.status = "Нельзя выключить единственный монитор"
            tab.failed = true
            return
        }
        const arr = tab.clone()
        const name = arr[i].name
        arr[i].enabled = on
        arr[i].mirror = ""
        // Выключенный монитор больше не источник зеркала: его зеркала становятся обычными мониторами
        for (let j = 0; j < arr.length; j++) {
            if (arr[j].mirror === name) { arr[j].mirror = ""; Logic.placeRight(arr, j) }
        }
        if (on) Logic.placeRight(arr, i)
        tab.commit(arr)
    }

    // Пресет раскладки меняет черновик, на экран он попадает после «Применить»
    function applyPreset(id) {
        tab.commit(Logic.applyPreset(tab.mons, id, tab.baseIdx))
        tab.selected = -1
    }

    function togglePrimary(i) {
        const name = tab.mons[i].name
        tab.primary = tab.primary === name ? "" : name
        tab.dirty = true
        tab.status = ""
    }

    function apply() {
        if (!tab.canApply) return
        applier.lua = Logic.toLua(tab.mons, tab.primary)
        tab.status = "Применяю…"
        applier.running = true
    }

    // Текущий основной монитор: primary = "DP-3" в строке return { ... } файла monitors.lua
    Process {
        command: ["sh", "-c", "sed -n 's/.*primary *= *\"\\([^\"]*\\)\".*/\\1/p' \"$HOME/.config/hypr/conf/monitors.lua\" | head -1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: tab.primary = text.trim()
        }
    }

    Process {
        id: reader
        command: ["hyprctl", "monitors", "all", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: tab.load(text)
        }
    }

    Process {
        id: applier
        property string lua: ""
        command: [tab.scripts + "/set-monitors.sh", lua]
        onExited: code => {
            tab.status = code === 0 ? "Применено" : "Не удалось применить (код " + code + ")"
            tab.failed = code !== 0
            if (code === 0) tab.dirty = false
            refreshTimer.restart()
        }
    }

    // Hyprland применяет новый конфиг не мгновенно: читаем список заново чуть позже
    Timer {
        id: refreshTimer
        interval: 800
        onTriggered: reader.running = true
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        // Шапка: пояснение и кнопки «Применить», «Обновить», «Закрыть» (название показывает верхняя полоса панели)
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: "Расположение и сохранение раскладки"
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                color: Colors.text
                opacity: 0.7
                font.family: Settings.uiFontFamily
                font.pixelSize: 12
            }

            Rectangle {
                Layout.preferredWidth: 104
                Layout.preferredHeight: 34
                radius: Settings.r(999)
                color: tab.canApply ? Colors.primary : Settings.fill
                border.width: 0

                Text {
                    anchors.centerIn: parent
                    text: "Применить"
                    color: tab.canApply ? Colors.textOnPrimary : Colors.text
                    opacity: tab.canApply ? 1 : 0.5
                    font.family: Settings.uiFontFamily
                    font.pixelSize: 13
                    font.bold: true
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: tab.canApply ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: tab.apply()
                }
            }

            // Круглые кнопки: обновить список мониторов и закрыть панель
            Repeater {
                model: 2

                Rectangle {
                    id: iconBtn
                    required property int index

                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34
                    radius: Settings.r(999)
                    color: iconMouse.containsMouse ? Settings.fillHover : Settings.fill
                    border.width: 0

                    Text {
                        anchors.centerIn: parent
                        text: iconBtn.index === 0 ? "↻" : "✕"
                        color: Colors.text
                        font.family: Settings.uiFontFamily
                        font.pixelSize: 15
                    }
                    MouseArea {
                        id: iconMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (iconBtn.index === 0) reader.running = true
                            else tab.closeRequested()
                        }
                    }
                }
            }
        }

        Flickable {
            id: flick
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: col.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: col
                width: flick.width
                spacing: 10

                // 1. Раскладка: четыре пресета
                Text {
                    text: "Раскладка"
                    color: Colors.text
                    font.family: Settings.uiFontFamily
                    font.pixelSize: 14
                    font.bold: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: 4

                        Rectangle {
                            id: pcard
                            required property int index
                            readonly property var preset: tab.presets[index]
                            readonly property bool current: tab.activePreset === preset.id
                            // Положение значков [x, y, ширина, высота] в поле 56 × 34: a — базовый монитор, b — остальные
                            readonly property var geo: ({
                                single: { a: [14, 7, 28, 20] },
                                extend: { a: [4, 7, 28, 20], b: [36, 11, 16, 16] },
                                mirror: { a: [8, 4, 28, 20], b: [20, 10, 28, 20] },
                                others: { b: [14, 7, 28, 20] }
                            })[preset.id]
                            readonly property var ga: geo.a ?? [0, 0, 0, 0]
                            readonly property var gb: geo.b ?? [0, 0, 0, 0]

                            Layout.fillWidth: true
                            Layout.preferredWidth: 100
                            Layout.preferredHeight: 86
                            radius: Settings.r(14)
                            opacity: preset.ok ? 1 : 0.45
                            color: current ? Settings.fillActive
                                 : pMouse.containsMouse && preset.ok ? Settings.fillHover
                                 : Settings.fill
                            border.width: 0

                            Item {
                                width: 56
                                height: 34
                                anchors.top: parent.top
                                anchors.topMargin: 12
                                anchors.horizontalCenter: parent.horizontalCenter

                                Rectangle {
                                    visible: pcard.geo.a !== undefined
                                    x: pcard.ga[0]
                                    y: pcard.ga[1]
                                    width: pcard.ga[2]
                                    height: pcard.ga[3]
                                    radius: Settings.r(3)
                                    color: Qt.alpha(tab.monColors[0], 0.25)
                                    border.width: 1.5
                                    border.color: tab.monColors[0]
                                }
                                Rectangle {
                                    visible: pcard.geo.b !== undefined
                                    x: pcard.gb[0]
                                    y: pcard.gb[1]
                                    width: pcard.gb[2]
                                    height: pcard.gb[3]
                                    radius: Settings.r(3)
                                    color: Qt.alpha(tab.monColors[1], 0.25)
                                    border.width: 1.5
                                    border.color: tab.monColors[1]
                                }
                            }

                            Text {
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 10
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width - 8
                                horizontalAlignment: Text.AlignHCenter
                                text: pcard.preset.label
                                elide: Text.ElideRight
                                color: Colors.text
                                font.family: Settings.uiFontFamily
                                font.pixelSize: 12
                                font.bold: pcard.current
                            }

                            MouseArea {
                                id: pMouse
                                anchors.fill: parent
                                enabled: pcard.preset.ok
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: tab.applyPreset(pcard.preset.id)
                            }
                        }
                    }
                }

                // 2. Превью: перетаскивание мониторов
                Text {
                    text: "Превью"
                    color: Colors.text
                    font.family: Settings.uiFontFamily
                    font.pixelSize: 14
                    font.bold: true
                }

                Rectangle {
                    id: preview
                    Layout.fillWidth: true
                    Layout.preferredHeight: 170
                    radius: Settings.r(12)
                    color: Settings.fill
                    border.width: 0
                    clip: true

                    onWidthChanged: tab.recalc()
                    onHeightChanged: tab.recalc()

                    Text {
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        anchors.margins: 8
                        text: "перетащите · логические координаты"
                        color: Colors.text
                        opacity: 0.5
                        font.family: Settings.uiFontFamily
                        font.pixelSize: 11
                    }

                    Repeater {
                        model: tab.mons.length

                        Rectangle {
                            id: mrect
                            required property int index
                            readonly property var mon: tab.mons[index] ?? ({ enabled: false })
                            readonly property var lsize: Logic.logicalSize(mon)
                            readonly property bool isSelected: tab.selected === index
                            // Зеркало рисуется поверх источника со сдвигом, чтобы были видны оба
                            readonly property bool isMirror: (mon.mirror ?? "") !== ""
                            readonly property bool hasMirror: tab.mons.some(o => o.mirror === mon.name)
                            readonly property color tone: tab.monColors[index % tab.monColors.length]

                            visible: mon.enabled === true
                            x: tab.viewOx + mon.x * tab.viewK + (isMirror ? 12 : 0)
                            y: tab.viewOy + mon.y * tab.viewK + (isMirror ? 12 : 0)
                            z: isMirror ? 1 : 0
                            width: lsize.w * tab.viewK
                            height: lsize.h * tab.viewK
                            radius: Settings.r(6)
                            color: Qt.alpha(tone, isMirror ? 0.12 : isSelected ? 0.38 : 0.22)
                            border.width: isSelected ? 2 : 1.5
                            border.color: tone

                            // Подписи: зеркало внизу, его источник вверху (иначе два названия лягут друг на друга)
                            Column {
                                x: (parent.width - width) / 2
                                y: mrect.isMirror ? parent.height - height - 9
                                 : mrect.hasMirror ? 5
                                 : (parent.height - height) / 2
                                spacing: 2

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: mrect.mon.name ?? ""
                                    color: mrect.tone
                                    font.family: Settings.uiFontFamily
                                    font.pixelSize: 13
                                    font.bold: true
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    visible: mrect.width > 90 && !mrect.hasMirror
                                    text: mrect.isMirror
                                        ? "зеркало " + mrect.mon.mirror
                                        : mrect.mon.w + "×" + mrect.mon.h + " · " + Logic.fmtScale(mrect.mon.scale)
                                    color: mrect.tone
                                    opacity: 0.85
                                    font.family: Settings.uiFontFamily
                                    font.pixelSize: 10
                                }
                            }

                            MouseArea {
                                id: dragArea
                                anchors.fill: parent
                                cursorShape: mrect.isMirror ? Qt.PointingHandCursor : Qt.SizeAllCursor
                                preventStealing: true

                                property point startPoint: Qt.point(0, 0)
                                property real baseX: 0
                                property real baseY: 0

                                onPressed: mouse => {
                                    tab.selected = mrect.index
                                    // Зеркало не двигается: его положение — положение источника
                                    if (mrect.isMirror) return
                                    tab.dragging = true
                                    startPoint = dragArea.mapToItem(preview, mouse.x, mouse.y)
                                    baseX = mrect.mon.x
                                    baseY = mrect.mon.y
                                }
                                onPositionChanged: mouse => {
                                    if (!pressed || mrect.isMirror) return
                                    const p = dragArea.mapToItem(preview, mouse.x, mouse.y)
                                    tab.moveTo(mrect.index,
                                               baseX + (p.x - startPoint.x) / tab.viewK,
                                               baseY + (p.y - startPoint.y) / tab.viewK)
                                }
                                onReleased: {
                                    tab.dragging = false
                                    tab.recalc()
                                }
                                onCanceled: {
                                    tab.dragging = false
                                    tab.recalc()
                                }
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "Перетащите внешний монитор, чтобы переместить его. Края притягиваются."
                    wrapMode: Text.WordWrap
                    color: Colors.text
                    opacity: 0.7
                    font.family: Settings.uiFontFamily
                    font.pixelSize: 12
                }

                // 3. Список мониторов
                Text {
                    text: "Мониторы"
                    color: Colors.text
                    font.family: Settings.uiFontFamily
                    font.pixelSize: 14
                    font.bold: true
                }

                Text {
                    Layout.fillWidth: true
                    text: "Нажмите на монитор, чтобы изменить разрешение, частоту, масштаб и поворот."
                    wrapMode: Text.WordWrap
                    color: Colors.text
                    opacity: 0.7
                    font.family: Settings.uiFontFamily
                    font.pixelSize: 12
                }

                Repeater {
                    model: tab.mons.length

                    DisplayRow {
                        required property int index

                        Layout.fillWidth: true
                        mon: tab.mons[index] ?? ({ modes: [] })
                        expanded: tab.selected === index
                        isPrimary: tab.primary === (tab.mons[index]?.name ?? "")

                        onHeaderClicked: tab.selected = tab.selected === index ? -1 : index
                        onEnabledToggled: on => tab.setEnabled(index, on)
                        onResolutionPicked: (w, h) => tab.pickResolution(index, w, h)
                        onRefreshPicked: hz => tab.change(index, { hz: hz })
                        onScalePicked: scale => tab.change(index, { scale: scale })
                        onTransformPicked: transform => tab.change(index, { transform: transform })
                        onPrimaryRequested: tab.togglePrimary(index)
                    }
                }

                // 4. Предупреждение о наложении мониторов
                Text {
                    Layout.fillWidth: true
                    visible: tab.overlaps.length > 0
                    text: "! " + (tab.overlaps.length > 0 ? tab.overlaps[0][0] + " и " + tab.overlaps[0][1] : "") + " перекрываются: сдвиньте их в превью."
                    wrapMode: Text.WordWrap
                    color: Colors.error
                    font.family: Settings.uiFontFamily
                    font.pixelSize: 12
                }
            }
        }

        // 5. Строка состояния: результат последнего действия или текущий основной монитор
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            radius: Settings.r(12)
            color: Settings.fill
            border.width: 0

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 8

                Rectangle {
                    Layout.preferredWidth: 8
                    Layout.preferredHeight: 8
                    radius: 4
                    color: tab.failed ? Colors.error : applier.running ? Colors.tertiary : Colors.primary
                }
                Text {
                    Layout.fillWidth: true
                    text: tab.status !== "" ? tab.status
                        : tab.dirty ? "Есть неприменённые изменения"
                        : "Hyprland · основной при старте: " + (tab.primary !== "" ? tab.primary : "не выбран")
                    elide: Text.ElideRight
                    color: Colors.text
                    font.family: Settings.uiFontFamily
                    font.pixelSize: 12
                }
                Text {
                    text: "запись в monitors.lua"
                    color: Colors.text
                    opacity: 0.6
                    font.family: Settings.uiFontFamily
                    font.pixelSize: 12
                }
            }
        }
    }
}
