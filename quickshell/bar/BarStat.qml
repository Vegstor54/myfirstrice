import QtQuick
import ".."

// Показатель системы в баре: значок и значение. kind: "ram" — занятая память, "cpu" — загрузка процессора.
// Данные собирает state/SysStats.qml (опрос идёт, пока включён хотя бы один из этих модулей).
Item {
    id: stat

    property string kind: "cpu"

    readonly property int fontSize: Math.round(Settings.barHeight * 0.45)

    width: row.implicitWidth + 12
    height: Settings.barHeight

    // Ширина значения не прыгает от «7%» к «10%»: берётся по самому широкому значению
    TextMetrics {
        id: metrics
        font.family: Settings.uiFontFamily
        font.pixelSize: stat.fontSize
        text: stat.kind === "ram" ? "99.9G" : "100%"
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        // Значок памяти нарисован (планка с контактами), чтобы не зависеть от шрифта
        Item {
            visible: stat.kind === "ram"
            width: 16
            height: 10
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                anchors.fill: parent
                radius: 2
                color: "transparent"
                border.width: 1.5
                border.color: Colors.text
            }
            Row {
                anchors.centerIn: parent
                spacing: 2
                Repeater {
                    model: 3
                    Rectangle { width: 2; height: 4; color: Colors.text }
                }
            }
        }

        // Значок процессора: глиф Nerd Font «microchip» (U+F2DB)
        Text {
            visible: stat.kind === "cpu"
            anchors.verticalCenter: parent.verticalCenter
            text: ""
            color: Colors.text
            font.family: "Symbols Nerd Font"
            font.pixelSize: stat.fontSize
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: metrics.width
            text: stat.kind === "ram" ? SysStats.ramText : SysStats.cpuText
            color: Colors.text
            font.family: Settings.uiFontFamily
            font.pixelSize: stat.fontSize
        }
    }
}
