import QtQuick

// Правая часть бара: сеть, звук, уведомления в одной группе.
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

    // ---- Кнопка группы: значок и необязательная подпись ----
    component IndicatorButton: Rectangle {
        id: btn
        property string glyph: ""
        property string label: ""
        property real dim: 1
        property bool active: false
        signal clicked()
        signal middleClicked()
        signal scrolled(int delta)

        height: Settings.barHeight - 12
        width: Math.max(height, content.implicitWidth + 12)
        radius: height / 2
        color: active ? Qt.rgba(1, 1, 1, 0.24)
             : area.containsMouse ? Qt.rgba(1, 1, 1, 0.16)
             : "transparent"

        Row {
            id: content
            anchors.centerIn: parent
            spacing: 4
            opacity: btn.dim

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: btn.glyph
                color: Colors.text
                font.family: "Symbols Nerd Font"
                font.pixelSize: Math.round(Settings.barHeight * 0.45)
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: btn.label !== ""
                text: btn.label
                color: Colors.text
                font.family: Settings.uiFontFamily
                font.pixelSize: Math.round(Settings.barHeight * 0.4)
            }
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                if (mouse.button === Qt.MiddleButton) btn.middleClicked()
                else btn.clicked()
            }
            onWheel: wheel => btn.scrolled(wheel.angleDelta.y)
        }
    }

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
