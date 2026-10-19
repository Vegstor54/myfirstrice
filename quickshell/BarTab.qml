import QtQuick
import QtQuick.Layouts

// Настройки бара: размер, кнопка с логотипом (открывает панель), рабочие столы.
// Всё сохраняется в Settings (settings.json), бар меняется сразу.
ColumnLayout {
    id: tab
    spacing: 16

    Text {
        text: "Размер бара"
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
                { id: "small",  label: "Маленький" },
                { id: "medium", label: "Средний" },
                { id: "large",  label: "Большой" }
            ]

            Rectangle {
                id: sizeChip
                required property var modelData
                readonly property bool selected: Settings.barSize === modelData.id

                Layout.fillWidth: true
                Layout.preferredHeight: 36
                radius: 999
                color: selected ? Colors.primary
                     : sizeMouse.containsMouse ? Colors.surfaceContainerHighest
                     : Colors.surfaceContainerHigh

                Text {
                    anchors.centerIn: parent
                    text: sizeChip.modelData.label
                    color: sizeChip.selected ? Colors.textOnPrimary : Colors.text
                    font.family: Settings.uiFontFamily
                    font.pixelSize: 13
                }
                MouseArea {
                    id: sizeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Settings.barSize = sizeChip.modelData.id
                }
            }
        }
    }

    Text {
        text: "Кнопка с логотипом"
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
                { value: true,  label: "Показывать" },
                { value: false, label: "Скрыть" }
            ]

            Rectangle {
                id: logoChip
                required property var modelData
                readonly property bool selected: Settings.showLogo === modelData.value

                Layout.fillWidth: true
                Layout.preferredHeight: 36
                radius: 999
                color: selected ? Colors.primary
                     : logoMouse.containsMouse ? Colors.surfaceContainerHighest
                     : Colors.surfaceContainerHigh

                Text {
                    anchors.centerIn: parent
                    text: logoChip.modelData.label
                    color: logoChip.selected ? Colors.textOnPrimary : Colors.text
                    font.family: Settings.uiFontFamily
                    font.pixelSize: 13
                }
                MouseArea {
                    id: logoMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Settings.showLogo = logoChip.modelData.value
                }
            }
        }
    }

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

            Rectangle {
                id: wsChip
                required property var modelData
                readonly property bool selected: Settings.wsMode === modelData.id

                Layout.fillWidth: true
                Layout.preferredHeight: 36
                radius: 999
                color: selected ? Colors.primary
                     : wsMouse.containsMouse ? Colors.surfaceContainerHighest
                     : Colors.surfaceContainerHigh

                Text {
                    anchors.centerIn: parent
                    text: wsChip.modelData.label
                    color: wsChip.selected ? Colors.textOnPrimary : Colors.text
                    font.family: Settings.uiFontFamily
                    font.pixelSize: 13
                }
                MouseArea {
                    id: wsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Settings.wsMode = wsChip.modelData.id
                }
            }
        }
    }

    Item { Layout.fillHeight: true }
}
