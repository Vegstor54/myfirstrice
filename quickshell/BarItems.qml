import Quickshell
import QtQuick

// Содержимое бара: четыре элемента (логотип, рабочие столы, часы, значки справа).
// Каждый стоит в одной из трёх зон — слева, по центру или справа — и его можно перетащить
// мышью, как значки на панели задач Windows: остальные расступаются прямо во время
// перетаскивания, а положение запоминается в Settings (barLeft / barCenter / barRight).
// Позиции считаются здесь, а не Row'ом, чтобы элемент мог переехать в другую зону,
// не пересоздаваясь посреди перетаскивания.
Item {
    id: root

    // id активного рабочего стола на этом мониторе, QuickMenu и имя монитора (передаёт shell.qml)
    property int activeId: -1
    property var menu: null
    property var clockMenu: null
    property string screenName: ""

    readonly property int gap: 6
    readonly property var zones: ["left", "center", "right"]
    // Зона по умолчанию для каждого элемента: сюда попадают новые и потерянные
    readonly property var defaultZone: ({
        logo: "left", workspaces: "left", clock: "center", media: "center", cava: "center",
        tray: "right",
        network: "right", bluetooth: "right", sound: "right", notifications: "right"
    })
    // Старый ключ «indicators» (все значки одним блоком) заменяется на четыре отдельных
    readonly property var legacyKeys: ({
        indicators: ["network", "bluetooth", "sound", "notifications"]
    })

    // Элементы по ключам: для расчёта позиций
    readonly property var slots: ({
        logo: logoSlot, workspaces: wsSlot, clock: clockSlot, media: mediaSlot, cava: cavaSlot, tray: traySlot,
        network: netSlot, bluetooth: btSlot, sound: sndSlot, notifications: ntfSlot
    })

    // ---- Раскладка ----
    function parseList(s) {
        return s.split(",").map(x => x.trim()).filter(x => x.length > 0)
    }

    // Приводит сохранённую раскладку к корректной: без неизвестных и повторов, с недостающими
    function normalize(l) {
        const seen = {}
        const out = { left: [], center: [], right: [] }
        for (const z of zones)
            for (const k0 of l[z])
                for (const k of (legacyKeys[k0] ?? [k0]))
                    if (defaultZone[k] !== undefined && !seen[k]) { seen[k] = true; out[z].push(k) }
        for (const k of Object.keys(defaultZone))
            if (!seen[k]) out[defaultZone[k]].push(k)
        return out
    }

    readonly property var stored: normalize({
        left: parseList(Settings.barLeft),
        center: parseList(Settings.barCenter),
        right: parseList(Settings.barRight)
    })

    // Во время перетаскивания показываем предварительную раскладку, сохраняем при отпускании
    property var preview: null
    readonly property var layout: preview !== null ? preview : stored

    // ---- Группы значков ----
    // Значки справа можно собирать в «папки»: бросить один на другой, и они объединятся в одну
    // «таблетку»; потянуть значок из группы вниз, и он выйдет из неё. Группы хранятся в
    // Settings.indGroups: группы через "|", значки в группе через ",".
    readonly property var indOrder: ["network", "bluetooth", "sound", "notifications"]

    // Во время перетаскивания группы могут меняться (значок вытащили из группы)
    property var groupsDraft: null
    readonly property var groups: groupsDraft !== null ? groupsDraft : parseGroups(Settings.indGroups)

    function isInd(k) { return indOrder.indexOf(k) >= 0 }

    function parseGroups(s) {
        const seen = {}
        const res = []
        for (const g of s.split("|")) {
            const m = g.split(",").map(x => x.trim()).filter(k => isInd(k) && !seen[k])
            for (const k of m) seen[k] = true
            if (m.length > 0) res.push(m)
        }
        for (const k of indOrder) if (!seen[k]) res.push([k])
        return res
    }

    function serializeGroups(gs) { return gs.map(g => g.join(",")).join("|") }

    // Группа хранится в элементе своего первого значка; у остальных членов группы своего элемента нет
    function groupOf(leader) { return groups.find(g => g[0] === leader) }
    function followers(key) { const g = groupOf(key); return g ? g.slice(1) : [] }
    // Что реально показывать в группе: только включённые модули (Bluetooth ещё и если есть адаптер)
    function activeMembers(leader) {
        const g = groupOf(leader)
        if (!g) return []
        return g.filter(m => Settings.moduleOn(m) && (m !== "bluetooth" || SysState.hasBluetooth))
    }

    // ---- Позиции ----
    function isVisible(k) { return slots[k].visible }
    function widthOf(k) { return slots[k].width }
    // Крайним круглым элементам нужен небольшой отступ, квадратикам столов побольше
    function edgeOf(k) { return k === "logo" || indOrder.indexOf(k) >= 0 ? 4 : 10 }

    function layoutX(key) {
        const L = layout
        const left = L.left.filter(isVisible)
        const center = L.center.filter(isVisible)
        const right = L.right.filter(isVisible)

        let i = left.indexOf(key)
        if (i >= 0) {
            let x = edgeOf(left[0])
            for (let j = 0; j < i; j++) x += widthOf(left[j]) + gap
            return x
        }

        i = right.indexOf(key)
        if (i >= 0) {
            let x = width - edgeOf(right[right.length - 1])
            for (let j = right.length - 1; j >= i; j--) {
                x -= widthOf(right[j])
                if (j > i) x -= gap
            }
            return x
        }

        i = center.indexOf(key)
        if (i < 0) return 0
        let total = gap * (center.length - 1)
        for (const k of center) total += widthOf(k)
        let x = (width - total) / 2
        for (let j = 0; j < i; j++) x += widthOf(center[j]) + gap
        return x
    }

    // ---- Перетаскивание ----
    property string dragKey: ""
    property real dragX: 0
    // Где в баре стояла мышь при нажатии и на каком расстоянии от левого края элемента
    // (grab < 0 — держать за середину)
    property real pointerX0: 0
    property real grab: 0
    // Значок внутри группы, за который взялись (его можно вытащить из группы)
    property string pressedModule: ""
    // Над каким значком завис перетаскиваемый (mergeCand) и готов ли он к слиянию (mergeTarget)
    property string mergeCand: ""
    property string mergeTarget: ""

    function beginDrag(slot, pressX) {
        pointerX0 = layoutX(slot.key) + pressX
        grab = pressX
        pressedModule = slot.moduleAt(pressX)
        dragX = layoutX(slot.key)
        mergeCand = ""
        mergeTarget = ""
        dragKey = slot.key
        preview = layout
    }

    // Вытаскивает значок из группы: он становится отдельной «таблеткой», и перетаскивание
    // продолжается уже с ним
    function detach(module) {
        const next = []
        for (const g of groups) {
            if (g[0] === dragKey) {
                next.push(g.filter(m => m !== module))
                next.push([module])
            } else next.push(g)
        }
        groupsDraft = next
        dragKey = module
        pressedModule = ""
        grab = -1
    }

    function dragMoved(tx, ty) {
        if (dragKey === "") return

        // Потянули значок из группы вниз или вверх: вынимаем его
        const own = groupOf(dragKey)
        if (own && own.length > 1 && pressedModule !== "" && Math.abs(ty) > Settings.barHeight * 0.6)
            detach(pressedModule)

        const w = widthOf(dragKey)
        dragX = Math.max(0, Math.min(width - w, pointerX0 + tx - (grab < 0 ? w / 2 : grab)))
        const c = dragX + w / 2

        // Завис над другим значком: пока он там, порядок не меняем, а через паузу готовим слияние
        let cand = ""
        if (isInd(dragKey)) {
            for (const k of indOrder) {
                if (k === dragKey || !groupOf(k) || !isVisible(k)) continue
                const half = Math.max(8, widthOf(k) * 0.35)
                if (Math.abs(c - (layoutX(k) + widthOf(k) / 2)) < half) cand = k
            }
        }
        if (cand !== "") {
            if (cand !== mergeCand) {
                mergeCand = cand
                mergeTarget = ""
                mergeTimer.restart()
            }
            return
        }
        if (mergeCand !== "") {
            mergeCand = ""
            mergeTarget = ""
            mergeTimer.stop()
        }

        // Зона по центру перетаскиваемого элемента: треть бара слева, в середине, справа
        const zone = c < width / 3 ? "left" : c > width * 2 / 3 ? "right" : "center"

        // Группа значков переезжает целиком: остальные её члены встают следом за первым
        const fol = followers(dragKey)
        const next = {}
        for (const z of zones) next[z] = layout[z].filter(k => k !== dragKey && fol.indexOf(k) < 0)

        // Куда вставить: после последнего видимого соседа, чей центр левее
        let at = 0
        const others = next[zone]
        for (let j = 0; j < others.length; j++) {
            if (isVisible(others[j]) && layoutX(others[j]) + widthOf(others[j]) / 2 < c) at = j + 1
        }
        others.splice(at, 0, dragKey, ...fol)

        if (JSON.stringify(next) !== JSON.stringify(layout)) preview = next
    }

    function writeLayout(L) {
        Settings.barLeft = L.left.join(",")
        Settings.barCenter = L.center.join(",")
        Settings.barRight = L.right.join(",")
    }

    // Бросили на значок: группа key вливается в группу target и встаёт сразу после неё
    function merge(key, target, draft) {
        const gs = draft !== null ? draft : parseGroups(Settings.indGroups)
        const ga = gs.find(g => g[0] === key)
        const gt = gs.find(g => g[0] === target)
        if (!ga || !gt) return
        const next = gs.filter(g => g !== ga).map(g => g === gt ? g.concat(ga) : g)

        const L = {}
        for (const z of zones) L[z] = stored[z].filter(k => ga.indexOf(k) < 0)
        const tz = zones.find(z => L[z].indexOf(target) >= 0)
        if (tz !== undefined) L[tz].splice(L[tz].indexOf(target) + 1, 0, ...ga)

        Settings.indGroups = serializeGroups(next)
        writeLayout(L)
    }

    function endDrag() {
        if (dragKey === "") return
        const key = dragKey
        const target = mergeTarget
        const p = preview
        const draft = groupsDraft
        mergeTimer.stop()
        dragKey = ""
        mergeCand = ""
        mergeTarget = ""
        preview = null
        groupsDraft = null

        if (target !== "") {
            merge(key, target, draft)
            return
        }
        if (draft !== null && serializeGroups(draft) !== serializeGroups(parseGroups(Settings.indGroups)))
            Settings.indGroups = serializeGroups(draft)
        if (p !== null && JSON.stringify(p) !== JSON.stringify(stored)) writeLayout(p)
    }

    // Пауза над значком: после неё он «раскрывается» для слияния
    Timer {
        id: mergeTimer
        interval: 400
        onTriggered: if (root.mergeCand !== "") root.mergeTarget = root.mergeCand
    }

    SystemClock { id: clock; precision: Settings.clockTicksSeconds ? SystemClock.Seconds : SystemClock.Minutes }

    // Кнопка с логотипом: открывает панель, как SUPER+S
    BarSlot {
        id: logoSlot
        key: "logo"
        host: root
        visible: Settings.showLogo

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: Settings.barHeight - 8
            height: width
            radius: Settings.barRounded ? width / 2 : 0
            color: buttonMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.18) : "transparent"

            // Значок — глиф Nerd Font (U+F303), тот же, что в терминале.
            // Нужен установленный шрифт Symbols Nerd Font; без него Qt ищет глиф в других шрифтах
            Text {
                anchors.centerIn: parent
                text: ""
                color: Colors.text
                font.family: "Symbols Nerd Font"
                font.pixelSize: Math.round(Settings.barHeight * 0.55)
            }

            MouseArea {
                id: buttonMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["quickshell", "ipc", "call", "panel", "toggle"])
            }
        }
    }

    // Рабочие столы: режим и вид задаются в Style -> Бар (см. Workspaces.qml)
    BarSlot {
        id: wsSlot
        key: "workspaces"
        host: root
        visible: Settings.moduleOn("workspaces")

        Workspaces {
            anchors.verticalCenter: parent.verticalCenter
            activeId: root.activeId
        }
    }

    // Часы
    BarSlot {
        id: clockSlot
        key: "clock"
        host: root
        visible: Settings.moduleOn("clock")

        // Клик открывает меню часов (ClockMenu.qml)
        Rectangle {
            id: clockButton
            anchors.verticalCenter: parent.verticalCenter
            width: clockText.implicitWidth + 20
            height: Settings.barHeight - 8
            radius: Settings.barRounded ? height / 2 : 0
            color: clockMouse.containsMouse
                   || (root.clockMenu !== null && root.clockMenu.shown && root.clockMenu.monitor === root.screenName)
                   ? Qt.rgba(1, 1, 1, 0.18) : "transparent"

            Text {
                id: clockText
                anchors.centerIn: parent
                color: Colors.text
                font.family: Settings.uiFontFamily
                font.pixelSize: Math.round(Settings.barHeight * 0.5)
                text: Qt.formatDateTime(clock.date, Settings.clockFormat)
            }

            MouseArea {
                id: clockMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.clockMenu?.toggle(root.screenName,
                    clockButton.mapToItem(null, clockButton.width / 2, 0).x + Settings.barEdge)
            }
        }
    }

    // Название играющего трека (BarMedia.qml): виден, только когда что-то играет или стоит на паузе
    BarSlot {
        id: mediaSlot
        key: "media"
        host: root
        visible: Settings.moduleOn("media") && mediaLoader.item !== null && mediaLoader.item.shown

        Loader {
            id: mediaLoader
            anchors.verticalCenter: parent.verticalCenter
            source: "BarMedia.qml"
        }
    }

    // Cava: столбики-эквалайзер (BarCava.qml), виден, только если cava установлена
    BarSlot {
        id: cavaSlot
        key: "cava"
        host: root
        visible: Settings.moduleOn("cava") && cavaLoader.item !== null && cavaLoader.item.shown

        Loader {
            id: cavaLoader
            anchors.verticalCenter: parent.verticalCenter
            source: "BarCava.qml"
        }
    }

    // Трей: значки приложений (BarTray.qml), виден, только если в трее что-то есть
    BarSlot {
        id: traySlot
        key: "tray"
        host: root
        visible: Settings.moduleOn("tray") && trayLoader.item !== null && trayLoader.item.count > 0

        Loader {
            id: trayLoader
            anchors.verticalCenter: parent.verticalCenter
            source: "BarTray.qml"
        }
    }

    // Значки справа: сеть, Bluetooth, звук, уведомления. Каждый можно выключить, а соседние —
    // объединять в группы (Style -> Бар); группа — одна «таблетка» (см. BarIndicators.qml).
    // Четыре одинаковых элемента: группа живёт в элементе своего первого модуля.
    BarSlot {
        id: netSlot
        key: "network"
        host: root
        visible: root.activeMembers("network").length > 0

        BarIndicators {
            anchors.verticalCenter: parent.verticalCenter
            menu: root.menu
            screenName: root.screenName
            modules: root.activeMembers("network")
        }
    }

    BarSlot {
        id: btSlot
        key: "bluetooth"
        host: root
        visible: root.activeMembers("bluetooth").length > 0

        BarIndicators {
            anchors.verticalCenter: parent.verticalCenter
            menu: root.menu
            screenName: root.screenName
            modules: root.activeMembers("bluetooth")
        }
    }

    BarSlot {
        id: sndSlot
        key: "sound"
        host: root
        visible: root.activeMembers("sound").length > 0

        BarIndicators {
            anchors.verticalCenter: parent.verticalCenter
            menu: root.menu
            screenName: root.screenName
            modules: root.activeMembers("sound")
        }
    }

    BarSlot {
        id: ntfSlot
        key: "notifications"
        host: root
        visible: root.activeMembers("notifications").length > 0

        BarIndicators {
            anchors.verticalCenter: parent.verticalCenter
            menu: root.menu
            screenName: root.screenName
            modules: root.activeMembers("notifications")
        }
    }
}
