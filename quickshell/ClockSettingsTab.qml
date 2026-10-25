import Quickshell
import QtQuick
import QtQuick.Layouts

// Настройки модуля «Часы»: секунды, 12/24 часа, дата рядом со временем, свой формат.
// Сохраняется в Settings, часы в баре меняются сразу.
Flickable {
    id: tab
    clip: true
    contentWidth: width
    contentHeight: col.implicitHeight
    boundsBehavior: Flickable.StopAtBounds

    SystemClock { id: clock; precision: SystemClock.Seconds }

    ColumnLayout {
        id: col
        width: tab.width
        spacing: 16

        // Как часы выглядят сейчас
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            radius: Settings.r(16)
            color: Colors.surfaceContainerHigh

            Text {
                anchors.centerIn: parent
                color: Colors.text
                font.family: Settings.uiFontFamily
                font.pixelSize: 20
                text: Qt.formatDateTime(clock.date, Settings.clockFormat)
            }
        }

        Text {
            text: "Время"
            color: Colors.text
            font.family: Settings.uiFontFamily
            font.pixelSize: 14
            font.bold: true
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            BarChip {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                label: "24 часа"
                selected: Settings.clock24
                onClicked: Settings.clock24 = true
            }
            BarChip {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                label: "12 часов"
                selected: !Settings.clock24
                onClicked: Settings.clock24 = false
            }
            BarChip {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                label: "Секунды"
                selected: Settings.clockSeconds
                onClicked: Settings.clockSeconds = !Settings.clockSeconds
            }
        }

        Text {
            text: "Дата рядом со временем"
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
                    { id: "none",    label: "Нет" },
                    { id: "short",   label: "Коротко" },
                    { id: "weekday", label: "С днём недели" }
                ]

                BarChip {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    label: modelData.label
                    selected: Settings.clockDate === modelData.id
                    onClicked: Settings.clockDate = modelData.id
                }
            }
        }

        Text {
            text: "Свой формат"
            color: Colors.text
            font.family: Settings.uiFontFamily
            font.pixelSize: 14
            font.bold: true
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            radius: Settings.r(999)
            color: Colors.surfaceContainerHigh
            border.width: customInput.activeFocus ? 1 : 0
            border.color: Colors.primary

            TextInput {
                id: customInput
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                verticalAlignment: TextInput.AlignVCenter
                color: Colors.text
                selectionColor: Colors.primary
                selectedTextColor: Colors.textOnPrimary
                font.family: Settings.uiFontFamily
                font.pixelSize: 14
                clip: true
                text: Settings.clockCustom
                onTextEdited: Settings.clockCustom = text

                Text {
                    visible: customInput.text === ""
                    anchors.verticalCenter: parent.verticalCenter
                    text: "например  ddd d MMM  HH:mm"
                    color: Colors.text
                    opacity: 0.4
                    font.family: Settings.uiFontFamily
                    font.pixelSize: 14
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: "Если поле заполнено, оно заменяет настройки выше. Буквы формата Qt: HH и h — часы, mm — минуты, ss — секунды, AP — AM/PM, ddd — день недели, d — число, MMM — месяц. Чтобы вернуться к обычному виду, очистите поле. После ввода нажмите «назад» вверху."
            wrapMode: Text.WordWrap
            color: Colors.text
            opacity: 0.7
            font.family: Settings.uiFontFamily
            font.pixelSize: 13
        }
    }
}
