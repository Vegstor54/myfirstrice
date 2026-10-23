import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick

// Модуль бара «Трей»: значки приложений (StatusNotifierItem: nm-applet, Discord, Steam, Telegram...).
// Левая кнопка — действие приложения, средняя — второе действие, правая — его меню.
// Грузится через Loader и в qmldir не регистрируется: если в этой сборке Quickshell нет
// модуля Quickshell.Services.SystemTray, ломается только он, а не весь бар.
Rectangle {
    id: pill

    readonly property int count: SystemTray.items.values.length
    readonly property int iconSize: Math.round(Settings.barHeight * 0.55)

    height: Settings.barHeight - 8
    width: row.implicitWidth + 12
    radius: height / 2
    color: Qt.rgba(1, 1, 1, 0.10)

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Repeater {
            model: SystemTray.items

            MouseArea {
                id: area
                required property var modelData

                width: pill.iconSize
                height: pill.iconSize
                anchors.verticalCenter: parent.verticalCenter
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

                function openMenu() {
                    console.log("tray openMenu:", modelData.id, "window:", area.QsWindow.window)
                    // Меню рисует само приложение через Quickshell; координаты — в окне бара
                    const p = area.mapToItem(null, 0, area.height)
                    area.modelData.display(area.QsWindow.window, p.x, p.y)
                }

                onClicked: ev => {
                    console.log("tray click: button", ev.button, "item", modelData.id,
                                "hasMenu", modelData.hasMenu, "onlyMenu", modelData.onlyMenu)
                    if (ev.button === Qt.RightButton) {
                        if (modelData.hasMenu) openMenu()
                    } else if (ev.button === Qt.MiddleButton) {
                        modelData.secondaryActivate()
                    } else if (modelData.onlyMenu && modelData.hasMenu) {
                        openMenu()
                    } else {
                        modelData.activate()
                    }
                }

                IconImage {
                    anchors.fill: parent
                    source: area.modelData.icon
                    opacity: area.containsMouse ? 1 : 0.85
                }
            }
        }
    }
}
