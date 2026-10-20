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

    // Выбрана ли вкладка меню, открытая на этом мониторе
    function isActive(tabId) {
        return menu !== null && menu.shown && menu.tab === tabId && menu.monitor === screenName
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
            glyph: SysState.net === "ethernet" ? "" : ""
            dim: SysState.net === "none" ? 0.35 : 1
            active: group.isActive("network")
            onClicked: group.menu?.toggle("network", group.screenName)
        }

        // Bluetooth:  — значок bluetooth
        IndicatorButton {
            glyph: ""
            active: group.isActive("bluetooth")
            onClicked: group.menu?.toggle("bluetooth", group.screenName)
        }

        // Звук:  — громко,  — тихо,  — выключено
        IndicatorButton {
            glyph: SysState.muted || SysState.volume <= 0 ? "" : SysState.volume < 0.5 ? "" : ""
            label: Math.round(SysState.volume * 100) + "%"
            dim: SysState.muted ? 0.4 : 1
            active: group.isActive("sound")
            onClicked: group.menu?.toggle("sound", group.screenName)
            onMiddleClicked: SysState.toggleMute()
            onScrolled: delta => SysState.changeVolume(delta > 0 ? 0.05 : -0.05)
        }

        // Уведомления:  — колокольчик
        IndicatorButton {
            glyph: ""
            active: group.isActive("notifications")
            onClicked: group.menu?.toggle("notifications", group.screenName)
        }
    }
}
