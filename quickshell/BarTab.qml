import QtQuick
import QtQuick.Layouts

// Настройки бара: размер. Форма бара и интерфейса — на странице «Форма», кнопка с логотипом — в «Модули бара» (плитка «Лого»).
// Рабочие столы настраиваются на странице модуля «Столы» (Модули бара, шестерёнка).
// Всё сохраняется в Settings (settings.json), бар меняется сразу.
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
                    radius: Settings.r(999)
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
            text: "Расположение элементов"
            color: Colors.text
            font.family: Settings.uiFontFamily
            font.pixelSize: 14
            font.bold: true
        }

        Text {
            Layout.fillWidth: true
            text: "Перетаскивайте элементы прямо в баре: влево, в центр или вправо, и меняйте их порядок."
            wrapMode: Text.WordWrap
            color: Colors.text
            opacity: 0.7
            font.family: Settings.uiFontFamily
            font.pixelSize: 13
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            radius: Settings.r(999)
            color: resetMouse.containsMouse ? Colors.surfaceContainerHighest : Colors.surfaceContainerHigh

            Text {
                anchors.centerIn: parent
                text: "Сбросить расположение"
                color: Colors.text
                font.family: Settings.uiFontFamily
                font.pixelSize: 13
            }
            MouseArea {
                id: resetMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Settings.barLeft = "logo,workspaces"
                    Settings.barCenter = "clock"
                    Settings.barRight = "network,bluetooth,sound,notifications"
                }
            }
        }
    }
}
