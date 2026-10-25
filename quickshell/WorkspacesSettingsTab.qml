import QtQuick
import QtQuick.Layouts

// Настройки модуля «Столы»: какие рабочие столы показывать в баре.
// Сохраняется в Settings (wsMode), бар меняется сразу.
ColumnLayout {
    spacing: 16

    Text {
        text: "Рабочие столы"
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
                { id: "used", label: "Занятые" },
                { id: "5",    label: "1–5" },
                { id: "10",   label: "1–10" }
            ]

            BarChip {
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                label: modelData.label
                selected: Settings.wsMode === modelData.id
                onClicked: Settings.wsMode = modelData.id
            }
        }
    }

    Item { Layout.fillHeight: true }
}
