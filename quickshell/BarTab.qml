import QtQuick
import QtQuick.Layouts

// Настройки бара: размер, кнопка с логотипом (открывает панель), рабочие столы.
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
            radius: 999
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
