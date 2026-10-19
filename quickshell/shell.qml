import Quickshell
import Quickshell.Hyprland
import QtQuick

ShellRoot {
    Panel {}

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
            margins { top: 8; left: 16; right: 16 }
            implicitHeight: Settings.barHeight
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                radius: 999
                color: Colors[Settings.barColor] ?? Colors.primaryContainer
                border.width: 1
                border.color: Qt.lighter(color, 1.3)

                SystemClock { id: clock; precision: SystemClock.Minutes }

                // Кнопка слева: открывает панель, как SUPER+S
                Rectangle {
                    id: panelButton
                    anchors.left: parent.left
                    anchors.leftMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Settings.showLogo
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

                // Рабочие столы: режим и вид задаются в Style -> Бар (см. Workspaces.qml)
                Workspaces {
                    anchors.left: parent.left
                    anchors.leftMargin: Settings.showLogo ? Settings.barHeight + 2 : 8
                    anchors.verticalCenter: parent.verticalCenter
                    activeId: win.activeWorkspaceId
                }

                Text {
                    anchors.centerIn: parent
                    color: Colors.text
                    font.family: Settings.uiFontFamily
                    font.pixelSize: Math.round(Settings.barHeight * 0.5)
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                }
            }
        }
    }
}
