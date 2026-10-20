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

    // Выбрана ли вкладка меню, открытая на этом мониторе
    function isActive(tabId) {
        return menu !== null && menu.shown && menu.tab === tabId && menu.monitor === screenName
    }

    // Открывает меню под значком: передаёт его центр по горизонтали в координатах экрана
    function openMenu(tabId, button) {
        const x = button.mapToItem(null, button.width / 2, 0).x + Settings.barSideMargin
        menu?.toggle(tabId, screenName, x)
    }

    height: Settings.barHeight - 8
    width: row.implicitWidth + 4
    radius: height / 2
    color: Qt.rgba(1, 1, 1, 0.10)

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
            glyph: ""
            active: group.isActive("notifications")
            onClicked: group.openMenu("notifications", ntfBtn)
        }
    }
}
