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

                Text {
                    anchors.centerIn: parent
                    color: Colors.text
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                }
            }
        }
    }
}
