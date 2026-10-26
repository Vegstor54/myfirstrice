import QtQuick
import QtQuick.Layouts
import ".."

// Вкладка «Интернет»: статус сети и кнопка настроек. Используется в QuickMenu и в панели (Control Center).
ColumnLayout {
    id: tab
    spacing: 16

    // Нужно закрыть меню или панель (например, после запуска настроек сети)
    signal closeRequested()

    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        //  — wifi,  — проводное подключение
        Text {
            text: SysState.net === "ethernet" ? "" : ""
            color: Colors.text
            opacity: SysState.net === "none" ? 0.35 : 1
            font.family: "Symbols Nerd Font"
            font.pixelSize: 28
        }
        ColumnLayout {
            spacing: 2
            Text {
                text: SysState.net === "ethernet" ? "Проводное подключение"
                    : SysState.net === "wifi" ? "Wi-Fi"
                    : "Нет подключения"
                color: Colors.text
                font.family: Settings.uiFontFamily
                font.pixelSize: 15
                font.bold: true
            }
            Text {
                text: SysState.net === "none" ? "Сеть не найдена" : "Подключено"
                color: Colors.text
                opacity: 0.6
                font.family: Settings.uiFontFamily
                font.pixelSize: 12
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 36
        radius: Settings.r(999)
        color: netMouse.containsMouse ? Settings.fillHover : Settings.fill
        border.width: 0

        Text {
            anchors.centerIn: parent
            text: "Настройки сети"
            color: Colors.text
            font.family: Settings.uiFontFamily
            font.pixelSize: 13
        }
        MouseArea {
            id: netMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                tab.closeRequested()
                SysState.openNetwork()
            }
        }
    }

    Item { Layout.fillHeight: true }
}
