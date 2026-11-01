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

    readonly property string scripts: Quickshell.env("HOME") + "/.config/quickshell/scripts"

    // Модель всегда заменяется целиком (commit), а Repeater'ы ниже работают по числу мониторов
    // (model: mons.length), иначе каждое изменение пересоздавало бы строки и рвало перетаскивание
    property var mons: []
    property string primary: ""
    property int selected: -1
    property bool dirty: false
    property bool dragging: false
    property string status: ""

    // Параметры превью (масштаб и смещение); пока монитор тянут, не пересчитываются
    property real viewK: 0.05
    property real viewOx: 0
    property real viewOy: 0

    readonly property var overlaps: Logic.overlapPairs(mons)
    readonly property int enabledCount: mons.filter(m => m.enabled).length
    readonly property bool canApply: dirty && overlaps.length === 0 && !applier.running

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
        if (!tab.dragging) tab.recalc()
    }

    function load(text) {
        let list
        try { list = JSON.parse(text) }
        catch (e) {
            tab.status = "Не удалось прочитать список мониторов"
            return
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
            return
        }
        const arr = tab.clone()
        arr[i].enabled = on
        if (on) Logic.placeRight(arr, i)
        tab.commit(arr)
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
        spacing: 10

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
                spacing: 12

                Text {
                    text: "Расположение"
                    color: Colors.text
                    font.family: Settings.uiFontFamily
                    font.pixelSize: 14
                    font.bold: true
                }

                Rectangle {
                    id: preview
                    Layout.fillWidth: true
                    Layout.preferredHeight: 150
                    radius: Settings.r(12)
                    color: Settings.fill
                    border.width: 0
                    clip: true

                    onWidthChanged: tab.recalc()
                    onHeightChanged: tab.recalc()

                    Repeater {
                        model: tab.mons.length

                        Rectangle {
                            id: mrect
                            required property int index
                            readonly property var mon: tab.mons[index] ?? ({ enabled: false })
                            readonly property var lsize: Logic.logicalSize(mon)
                            readonly property bool isSelected: tab.selected === index

                            visible: mon.enabled === true
                            x: tab.viewOx + mon.x * tab.viewK
                            y: tab.viewOy + mon.y * tab.viewK
                            width: lsize.w * tab.viewK
                            height: lsize.h * tab.viewK
                            radius: Settings.r(6)
                            color: isSelected ? Qt.alpha(Colors.primary, 0.35) : Settings.fillActive
                            border.width: isSelected ? 2 : 1
                            border.color: isSelected ? Colors.primary : Qt.alpha(Colors.text, 0.35)

                            Column {
                                anchors.centerIn: parent
                                spacing: 2

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: mrect.mon.name ?? ""
                                    color: Colors.text
                                    font.family: Settings.uiFontFamily
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    visible: mrect.width > 80
                                    text: mrect.mon.w + "×" + mrect.mon.h
                                    color: Colors.text
                                    opacity: 0.7
                                    font.family: Settings.uiFontFamily
                                    font.pixelSize: 10
                                }
                            }

                            MouseArea {
                                id: dragArea
                                anchors.fill: parent
                                cursorShape: Qt.SizeAllCursor
                                preventStealing: true

                                property point startPoint: Qt.point(0, 0)
                                property real baseX: 0
                                property real baseY: 0

                                onPressed: mouse => {
                                    tab.selected = mrect.index
                                    tab.dragging = true
                                    startPoint = dragArea.mapToItem(preview, mouse.x, mouse.y)
                                    baseX = mrect.mon.x
                                    baseY = mrect.mon.y
                                }
                                onPositionChanged: mouse => {
                                    if (!pressed) return
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
                    text: "Перетащите монитор в превью, чтобы изменить расположение. Края притягиваются."
                    wrapMode: Text.WordWrap
                    color: Colors.text
                    opacity: 0.7
                    font.family: Settings.uiFontFamily
                    font.pixelSize: 12
                }

                Text {
                    text: "Мониторы"
                    color: Colors.text
                    font.family: Settings.uiFontFamily
                    font.pixelSize: 14
                    font.bold: true
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

                Text {
                    Layout.fillWidth: true
                    visible: tab.overlaps.length > 0
                    text: "Мониторы " + (tab.overlaps.length > 0 ? tab.overlaps[0][0] + " и " + tab.overlaps[0][1] : "") + " перекрываются: сдвиньте их в превью."
                    wrapMode: Text.WordWrap
                    color: Colors.error
                    font.family: Settings.uiFontFamily
                    font.pixelSize: 12
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
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

            BarChip {
                Layout.preferredWidth: 110
                label: "Обновить"
                onClicked: reader.running = true
            }
        }

        Text {
            Layout.fillWidth: true
            visible: tab.status !== ""
            text: tab.status
            wrapMode: Text.WordWrap
            color: Colors.text
            opacity: 0.8
            font.family: Settings.uiFontFamily
            font.pixelSize: 12
        }
    }
}
