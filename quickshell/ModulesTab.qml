import QtQuick
import QtQuick.Layouts

// Модули бара: что показывать и как группировать значки справа (сеть, Bluetooth, звук, уведомления).
// Сохраняется в Settings (barOff, indGroups), бар меняется сразу.
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
        Text {
            text: "Модули"
            color: Colors.text
            font.family: Settings.uiFontFamily
            font.pixelSize: 14
            font.bold: true
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 3
            rowSpacing: 8
            columnSpacing: 8

            Repeater {
                model: [
                    { id: "workspaces",    label: "Столы" },
                    { id: "clock",         label: "Часы" },
                    { id: "network",       label: "Сеть" },
                    { id: "bluetooth",     label: "Bluetooth" },
                    { id: "sound",         label: "Звук" },
                    { id: "notifications", label: "Уведомления" }
                ]

                BarChip {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    label: modelData.label
                    selected: Settings.moduleOn(modelData.id)
                    onClicked: Settings.setModule(modelData.id, !selected)
                }
            }
        }

        Text {
            text: "Группировка значков"
            color: Colors.text
            font.family: Settings.uiFontFamily
            font.pixelSize: 14
            font.bold: true
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: [
                    { label: "Отдельно", value: "network|bluetooth|sound|notifications" },
                    { label: "Попарно",  value: "network,bluetooth|sound,notifications" },
                    { label: "Вместе",   value: "network,bluetooth,sound,notifications" }
                ]

                BarChip {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    label: modelData.label
                    selected: Settings.indGroups === modelData.value
                    onClicked: Settings.indGroups = modelData.value
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: "Попарно: сеть с Bluetooth и звук с уведомлениями. Каждую группу можно перетащить отдельно."
            wrapMode: Text.WordWrap
            color: Colors.text
            opacity: 0.7
            font.family: Settings.uiFontFamily
            font.pixelSize: 13
        }
    }
}
