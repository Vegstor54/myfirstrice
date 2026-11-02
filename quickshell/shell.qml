import Quickshell
import Quickshell.Hyprland
import QtQuick

ShellRoot {
    Panel {}

    // Выезжающее меню под баром: уведомления, интернет, звук (открывается из BarIndicators)
    QuickMenu { id: quickMenu }

    // Всплывающие карточки уведомлений (сам сервер уведомлений: NotificationState.qml)
    NotificationPopups {}

    // Меню часов: громкость, плеер, время и календарь (открывается кликом на часы в баре)
    ClockMenu { id: clockMenuScope }

    // Большая версия CPU и памяти (открывается кликом на кольцо или значение в баре)
    StatMenu { id: statMenuScope }

    // История буфера обмена (Super+V, quickshell ipc call clipboard toggle): cliphist
    ClipboardMenu {}

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            // Монитор Hyprland, на котором этот бар: по нему определяется активный воркспейс
            readonly property var monitor: Hyprland.monitorFor(modelData)
            readonly property int activeWorkspaceId:
                monitor?.activeWorkspace?.id ?? Hyprland.focusedWorkspace?.id ?? -1

            // Окно всегда во всю ширину экрана без отступов, а отступы бара делает его прямоугольник внутри.
            // Раньше отступы были полями самого окна и после перезапуска не всегда обновлялись под сохранённую форму:
            // бар оставался «плавающим» даже в прямом режиме. Свойства прямоугольника обновляются всегда.
            anchors { top: true; left: true; right: true }
            implicitHeight: Settings.barHeight + Settings.barTop
            color: "transparent"
            // Клики принимает только сам бар, а не прозрачные поля вокруг него. В стиле «острова»
            // общей подложки нет, поэтому принимают только три острова: между ними клики идут в окна под баром
            mask: Region {
                item: Settings.islands ? null : barRect
                Region { item: barItems.islandItems[0] }
                Region { item: barItems.islandItems[1] }
                Region { item: barItems.islandItems[2] }
            }

            Rectangle {
                id: barRect
                anchors {
                    fill: parent
                    topMargin: Settings.barTop
                    leftMargin: Settings.barEdge
                    rightMargin: Settings.barEdge
                }
                radius: Settings.barRounded ? 999 : 0
                // В стиле «острова» подложку рисуют сами острова (BarIsland в BarItems)
                color: Settings.islands ? "transparent" : (Colors[Settings.barColor] ?? Colors.primaryContainer)
                border.width: Settings.islands ? 0 : 1
                border.color: Qt.lighter(Colors[Settings.barColor] ?? Colors.primaryContainer, 1.3)

                // Элементы бара (логотип, столы, часы, значки) и их перетаскивание: см. BarItems.qml
                BarItems {
                    id: barItems
                    anchors.fill: parent
                    activeId: win.activeWorkspaceId
                    menu: quickMenu
                    clockMenu: clockMenuScope
                    statMenu: statMenuScope
                    screenName: win.modelData.name
                }
            }
        }
    }
}
