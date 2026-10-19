import Quickshell
import QtQuick

ShellRoot {
    Panel {}

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            anchors { top: true; left: true; right: true }
            margins { top: 8; left: 16; right: 16 }
            implicitHeight: 32
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
                    width: 24
                    height: 24
                    radius: 12
                    color: buttonMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.18) : "transparent"

                    // Логотип дистрибутива берётся из установленной темы иконок;
                    // если такой иконки нет, показывается запасной значок
                    Image {
                        id: logo
                        anchors.centerIn: parent
                        width: 16
                        height: 16
                        sourceSize: Qt.size(32, 32)
                        source: Quickshell.iconPath("distributor-logo-archlinux", "start-here")
                        fillMode: Image.PreserveAspectFit
                        visible: status === Image.Ready
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: logo.status !== Image.Ready
                        text: "≡"
                        color: Colors.text
                        font.family: Settings.uiFontFamily
                        font.pixelSize: 16
                    }

                    MouseArea {
                        id: buttonMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["quickshell", "ipc", "call", "panel", "toggle"])
                    }
                }

                Text {
                    anchors.centerIn: parent
                    color: Colors.text
                    font.family: Settings.uiFontFamily
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                }
            }
        }
    }
}
