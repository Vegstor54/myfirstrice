import QtQuick
import QtQuick.Layouts

// Модули бара: что показывать. Группировка значков делается перетаскиванием прямо в баре.
// Сохраняется в Settings (barOff), бар меняется сразу.
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
                    { id: "media",         label: "Трек" },
                    { id: "cava",          label: "Cava" },
                    { id: "tray",          label: "Трей" },
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
            Layout.fillWidth: true
            text: "Группы значков собираются прямо в баре: бросьте один значок на другой и чуть подержите, и они объединятся. Чтобы вынуть значок из группы, потяните его вниз."
            wrapMode: Text.WordWrap
            color: Colors.text
            opacity: 0.7
            font.family: Settings.uiFontFamily
            font.pixelSize: 13
        }
    }
}
