import QtQuick
import QtQuick.Layouts

// Модули бара: квадратные плитки с иконкой. Клик по плитке включает или выключает модуль,
// шестерёнка в углу (только у модулей с настройками) открывает страницу настроек этого модуля.
// Сохраняется в Settings (barOff), бар меняется сразу.
Flickable {
    id: tab
    clip: true
    contentWidth: width
    contentHeight: col.implicitHeight
    boundsBehavior: Flickable.StopAtBounds

    // Панель открывает по этому сигналу страницу настроек модуля
    signal openRequested(string moduleId)

    readonly property int gap: 8
    readonly property real cell: Math.floor((width - 2 * gap) / 3)

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
            rowSpacing: tab.gap
            columnSpacing: tab.gap

            Repeater {
                model: [
                    { id: "logo",          label: "Лого",        icon: "", settings: false },
                    { id: "workspaces",    label: "Столы",       icon: "", settings: true },
                    { id: "clock",         label: "Часы",        icon: "", settings: true },
                    { id: "media",         label: "Трек",        icon: "", settings: false },
                    { id: "cava",          label: "Cava",        icon: "", settings: false },
                    { id: "tray",          label: "Трей",        icon: "", settings: false },
                    { id: "network",       label: "Сеть",        icon: "", settings: false },
                    { id: "bluetooth",     label: "Bluetooth",   icon: "", settings: false },
                    { id: "sound",         label: "Звук",        icon: "", settings: false },
                    { id: "notifications", label: "Уведомления", icon: "", settings: false }
                ]

                Rectangle {
                    id: tile
                    required property var modelData
                    // Лого включается своим параметром showLogo, остальные модули — через barOff
                    readonly property bool on: modelData.id === "logo" ? Settings.showLogo : Settings.moduleOn(modelData.id)

                    Layout.preferredWidth: tab.cell
                    Layout.preferredHeight: tab.cell
                    radius: Settings.r(18)
                    color: on ? Colors.primary
                         : tileMouse.containsMouse ? Colors.surfaceContainerHighest
                         : Colors.surfaceContainerHigh
                    border.width: 1
                    border.color: Colors.border

                    MouseArea {
                        id: tileMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (tile.modelData.id === "logo") Settings.showLogo = !tile.on
                            else Settings.setModule(tile.modelData.id, !tile.on)
                        }
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: tile.modelData.icon
                            color: tile.on ? Colors.textOnPrimary : Colors.text
                            opacity: tile.on ? 1 : 0.7
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 26
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: tile.modelData.label
                            color: tile.on ? Colors.textOnPrimary : Colors.text
                            opacity: tile.on ? 1 : 0.7
                            font.family: Settings.uiFontFamily
                            font.pixelSize: 12
                        }
                    }

                    // Шестерёнка: настройки модуля (лежит поверх плитки, клик до плитки не доходит)
                    Rectangle {
                        visible: tile.modelData.settings
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 6
                        width: 26
                        height: 26
                        radius: Settings.r(13)
                        color: gearMouse.containsMouse
                               ? Qt.rgba(0, 0, 0, tile.on ? 0.18 : 0.3)
                               : Qt.rgba(0, 0, 0, tile.on ? 0.08 : 0.16)

                        Text {
                            anchors.centerIn: parent
                            text: ""
                            color: tile.on ? Colors.textOnPrimary : Colors.text
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 13
                        }
                        MouseArea {
                            id: gearMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: tab.openRequested(tile.modelData.id)
                        }
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: "Клик по плитке включает или выключает модуль, шестерёнка открывает его настройки. «Лого» — кнопка слева, открывающая панель. Группы значков собираются прямо в баре: бросьте один значок на другой и чуть подержите, и они объединятся. Чтобы вынуть значок из группы, потяните его вниз."
            wrapMode: Text.WordWrap
            color: Colors.text
            opacity: 0.7
            font.family: Settings.uiFontFamily
            font.pixelSize: 13
        }
    }
}
