import QtQuick

// Правая часть бара: сеть, Bluetooth, звук, уведомления в одной группе.
// Клик по значку открывает выезжающее меню (QuickMenu.qml) на нужной вкладке.
// Колесо мыши на значке звука меняет громкость, средняя кнопка включает и выключает звук.
// Значки — глифы Nerd Font (Symbols Nerd Font), как у кнопки с логотипом.
Rectangle {
    id: group

    // QuickMenu из shell.qml и имя монитора этого бара
    property var menu: null
    property string screenName: ""
    // Какие значки показывать в этой группе: network, bluetooth, sound, notifications
    property var modules: ["network", "bluetooth", "sound", "notifications"]
    function has(m) { return modules.indexOf(m) >= 0 }

    // Какой значок ближе всего к x (в координатах группы); нужно, чтобы вытащить его из группы
    function moduleAt(x) {
        const btns = [[netBtn, "network"], [btBtn, "bluetooth"], [sndBtn, "sound"], [ntfBtn, "notifications"]]
        let best = ""
        let bestDist = 1e9
        for (const [btn, m] of btns) {
            if (!btn.visible) continue
            const d = Math.abs(btn.mapToItem(group, btn.width / 2, 0).x - x)
            if (d < bestDist) { bestDist = d; best = m }
        }
        return best
    }

    // Выбрана ли вкладка меню, открытая на этом мониторе
    function isActive(tabId) {
        return menu !== null && menu.shown && menu.tab === tabId && menu.monitor === screenName
    }

    // Открывает меню под значком: передаёт его центр по горизонтали в координатах экрана
    function openMenu(tabId, button) {
        const x = button.mapToItem(null, button.width / 2, 0).x + Settings.barEdge
        // Меню покажет вкладки только этой группы значков
        menu?.toggle(tabId, screenName, x, modules)
    }

    height: Settings.barHeight - 8
    width: row.implicitWidth + 4
    radius: Settings.barRounded ? height / 2 : 0
    color: Qt.alpha(Colors.text, 0.10)

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 2

        // Сеть:  — wifi,  — проводное подключение; без сети значок тусклый
        IndicatorButton {
            id: netBtn
            visible: group.has("network")
            glyph: SysState.net === "ethernet" ? "" : ""
            dim: SysState.net === "none" ? 0.35 : 1
            active: group.isActive("network")
            onClicked: group.openMenu("network", netBtn)
        }

        // Bluetooth:  — значок bluetooth (виден, только если установлен bluez и есть адаптер)
        IndicatorButton {
            id: btBtn
            visible: group.has("bluetooth") && SysState.hasBluetooth
            glyph: ""
            active: group.isActive("bluetooth")
            onClicked: group.openMenu("bluetooth", btBtn)
        }

        // Звук:  — громко,  — тихо,  — выключено
        IndicatorButton {
            id: sndBtn
            visible: group.has("sound")
            glyph: SysState.muted || SysState.volume <= 0 ? "" : SysState.volume < 0.5 ? "" : ""
            label: Math.round(SysState.volume * 100) + "%"
            dim: SysState.muted ? 0.4 : 1
            active: group.isActive("sound")
            onClicked: group.openMenu("sound", sndBtn)
            onMiddleClicked: SysState.toggleMute()
            onScrolled: delta => SysState.changeVolume(delta > 0 ? 0.05 : -0.05)
        }

        // Уведомления:  — колокольчик
        IndicatorButton {
            id: ntfBtn
            visible: group.has("notifications")
            glyph: NotificationState.dnd ? "\uf1f6" : "\uf0f3"
            label: NotificationState.count > 0 ? String(NotificationState.count) : ""
            active: group.isActive("notifications")
            onClicked: group.openMenu("notifications", ntfBtn)
        }
    }
}
