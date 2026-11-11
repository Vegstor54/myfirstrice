import QtQuick
import QtQuick.Layouts
import ".."

// Настройки модуля «Сеть»: значок, скорость загрузки и отдачи, или то и другое.
// Сохраняется в Settings (netStyle), значок в баре меняется сразу.
Flickable {
    id: tab

    clip: true
    contentWidth: width
    contentHeight: col.implicitHeight
    boundsBehavior: Flickable.StopAtBounds

    ColumnLayout {
        id: col
        width: tab.width
        spacing: 16

        // Как значок выглядит сейчас (тот же BarIndicators, что в баре)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            radius: Settings.r(16)
            color: Settings.fill
            border.width: 0

            BarIndicators {
                anchors.centerIn: parent
                modules: ["network"]
            }
        }

        Text {
            text: "Вид"
            color: Colors.text
            font.family: Settings.uiFontFamily
            font.pixelSize: 14
            font.bold: true
        }

        // «Значок» — wifi или проводное, «Скорость» — ↓ загрузка и ↑ отдача, «Оба» — значок и скорость
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: [
                    { id: "icon",  label: "Значок" },
                    { id: "speed", label: "Скорость" },
                    { id: "both",  label: "Оба" }
                ]

                BarChip {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    label: modelData.label
                    selected: Settings.netStyle === modelData.id
                    onClicked: Settings.netStyle = modelData.id
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: "Скорость считается по физическим сетевым картам (Wi-Fi и проводным) и обновляется раз в 2 секунды. Клик по значку в баре открывает меню сети, как и раньше."
            wrapMode: Text.WordWrap
            color: Colors.text
            opacity: 0.7
            font.family: Settings.uiFontFamily
            font.pixelSize: 13
        }
    }
}
