//@ pragma UseQApplication
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

            anchors { top: true; left: true; right: true }
            margins { top: 8; left: Settings.barSideMargin; right: Settings.barSideMargin }
            implicitHeight: Settings.barHeight
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                radius: 999
                color: Colors[Settings.barColor] ?? Colors.primaryContainer
                border.width: 1
                border.color: Qt.lighter(color, 1.3)

                // Элементы бара (логотип, столы, часы, значки) и их перетаскивание: см. BarItems.qml
                BarItems {
                    anchors.fill: parent
                    activeId: win.activeWorkspaceId
                    menu: quickMenu
                    clockMenu: clockMenuScope
                    screenName: win.modelData.name
                }
            }
        }
    }
}
