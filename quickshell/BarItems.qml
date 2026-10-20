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
    property string screenName: ""

    readonly property int gap: 6
    readonly property var zones: ["left", "center", "right"]
    // Зона по умолчанию для каждого элемента: сюда попадают новые и потерянные
    readonly property var defaultZone: ({
        logo: "left", workspaces: "left", clock: "center",
        network: "right", bluetooth: "right", sound: "right", notifications: "right"
    })
    // Старый ключ «indicators» (все значки одним блоком) заменяется на четыре отдельных
    readonly property var legacyKeys: ({
        indicators: ["network", "bluetooth", "sound", "notifications"]
    })

    // Элементы по ключам: для расчёта позиций
    readonly property var slots: ({
        logo: logoSlot, workspaces: wsSlot, clock: clockSlot,
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
    readonly property var indOrder: ["network", "bluetooth", "sound", "notifications"]
    readonly property var groups: parseGroups(Settings.indGroups)

    function parseGroups(s) {
        const seen = {}
        const res = []
        for (const g of s.split("|")) {
            const m = g.split(",").map(x => x.trim()).filter(k => indOrder.indexOf(k) >= 0 && !seen[k])
            for (const k of m) seen[k] = true
            if (m.length > 0) res.push(m)
        }
        for (const k of indOrder) if (!seen[k]) res.push([k])
        return res
    }

    // Группа хранится в элементе своего первого модуля; у остальных членов группы своего элемента нет
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
    property real dragStartX: 0

    function beginDrag(slot) {
        dragStartX = layoutX(slot.key)
        dragX = dragStartX
        dragKey = slot.key
        preview = layout
    }

    function dragMoved(slot, tx) {
        if (dragKey !== slot.key) return
        dragX = Math.max(0, Math.min(width - slot.width, dragStartX + tx))
        const c = dragX + slot.width / 2

        // Зона по центру перетаскиваемого элемента: треть бара слева, в середине, справа
        const zone = c < width / 3 ? "left" : c > width * 2 / 3 ? "right" : "center"

        // Группа значков переезжает целиком: остальные её члены встают следом за первым
        const fol = followers(slot.key)
        const next = {}
        for (const z of zones) next[z] = layout[z].filter(k => k !== slot.key && fol.indexOf(k) < 0)

        // Куда вставить: после последнего видимого соседа, чей центр левее
        let at = 0
        const others = next[zone]
        for (let j = 0; j < others.length; j++) {
            if (isVisible(others[j]) && layoutX(others[j]) + widthOf(others[j]) / 2 < c) at = j + 1
        }
        others.splice(at, 0, slot.key, ...fol)

        if (JSON.stringify(next) !== JSON.stringify(layout)) preview = next
    }

    function endDrag() {
        if (dragKey === "") return
        const p = preview
        dragKey = ""
        preview = null
        if (p === null || JSON.stringify(p) === JSON.stringify(stored)) return
        Settings.barLeft = p.left.join(",")
        Settings.barCenter = p.center.join(",")
        Settings.barRight = p.right.join(",")
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }

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
            radius: width / 2
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

        Text {
            anchors.verticalCenter: parent.verticalCenter
            color: Colors.text
            font.family: Settings.uiFontFamily
            font.pixelSize: Math.round(Settings.barHeight * 0.5)
            text: Qt.formatDateTime(clock.date, "HH:mm")
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
