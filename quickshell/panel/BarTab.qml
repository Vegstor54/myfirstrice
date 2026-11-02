import QtQuick
import QtQuick.Layouts
import ".."

// Настройки бара: стиль (сплошной или острова) и размер. Форма бара и интерфейса — на странице «Форма», кнопка с логотипом — в «Модули бара» (плитка «Лого»).
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
            text: "Стиль бара"
            color: Colors.text
            font.family: Settings.uiFontFamily
            font.pixelSize: 14
            font.bold: true
        }

        // «Сплошной» — одна общая подложка; «Острова» — отдельная «таблетка» на левую, центральную и правую часть
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: [
                    { id: "solid",   label: "Сплошной" },
                    { id: "islands", label: "Острова" }
                ]

                Rectangle {
                    id: styleChip
                    required property var modelData
                    readonly property bool selected: Settings.barStyle === modelData.id

                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    radius: Settings.r(999)
                    color: selected ? Colors.primary
                         : styleMouse.containsMouse ? Settings.fillHover
                         : Settings.fill
                    border.width: 0

                    Text {
                        anchors.centerIn: parent
                        text: styleChip.modelData.label
                        color: styleChip.selected ? Colors.textOnPrimary : Colors.text
                        font.family: Settings.uiFontFamily
                        font.pixelSize: 13
                    }
                    MouseArea {
                        id: styleMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Settings.barStyle = styleChip.modelData.id
                    }
                }
            }
        }

        Text {
            text: "CPU и память"
            color: Colors.text
            font.family: Settings.uiFontFamily
            font.pixelSize: 14
            font.bold: true
        }

        // «Текст» — значок и значение; «Кольцо» — дуга-спидометр без стрелки с числом в центре
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: [
                    { id: "text",  label: "Текст" },
                    { id: "gauge", label: "Кольцо" }
                ]

                Rectangle {
                    id: statChip
                    required property var modelData
                    readonly property bool selected: Settings.statStyle === modelData.id

                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    radius: Settings.r(999)
                    color: selected ? Colors.primary
                         : statMouse.containsMouse ? Settings.fillHover
                         : Settings.fill
                    border.width: 0

                    Text {
                        anchors.centerIn: parent
                        text: statChip.modelData.label
                        color: statChip.selected ? Colors.textOnPrimary : Colors.text
                        font.family: Settings.uiFontFamily
                        font.pixelSize: 13
                    }
                    MouseArea {
                        id: statMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Settings.statStyle = statChip.modelData.id
                    }
                }
            }
        }

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
                         : sizeMouse.containsMouse ? Settings.fillHover
                         : Settings.fill
                    border.width: 0

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
            color: resetMouse.containsMouse ? Settings.fillHover : Settings.fill
            border.width: 0

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
