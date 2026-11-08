import QtQuick
import QtQuick.Layouts
import ".."

// Настройки модулей «CPU» и «Память» (kind: "cpu" или "ram"): вид, подпись, температура, значение памяти.
// Сохраняется в Settings, показатель в баре меняется сразу.
Flickable {
    id: tab

    property string kind: "cpu"

    readonly property string mode: Settings.statMode(kind)

    clip: true
    contentWidth: width
    contentHeight: col.implicitHeight
    boundsBehavior: Flickable.StopAtBounds

    ColumnLayout {
        id: col
        width: tab.width
        spacing: 16

        // Как показатель выглядит сейчас (тот же BarStat, что в баре)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            radius: Settings.r(16)
            color: Settings.fill
            border.width: 0

            BarStat {
                anchors.centerIn: parent
                kind: tab.kind
            }
        }

        Text {
            text: "Вид"
            color: Colors.text
            font.family: Settings.uiFontFamily
            font.pixelSize: 14
            font.bold: true
        }

        // «Текст» — значок и значение, «Кольцо» — дуга-спидометр, «Полоса» — сегментная полоска
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: [
                    { id: "text",  label: "Текст" },
                    { id: "gauge", label: "Кольцо" },
                    { id: "bar",   label: "Полоса" }
                ]

                BarChip {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    label: modelData.label
                    selected: tab.mode === modelData.id
                    onClicked: Settings.setStatMode(tab.kind, modelData.id)
                }
            }
        }

        // У кольца своя подпись и своё значение, поэтому эти параметры только для «Текста» и «Полосы»
        Text {
            visible: tab.mode !== "gauge"
            text: "Перед значением"
            color: Colors.text
            font.family: Settings.uiFontFamily
            font.pixelSize: 14
            font.bold: true
        }

        RowLayout {
            visible: tab.mode !== "gauge"
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: [
                    { id: "icon", label: "Значок" },
                    { id: "text", label: "Подпись" },
                    { id: "none", label: "Ничего" }
                ]

                BarChip {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    label: modelData.label
                    selected: Settings.statLabel(tab.kind) === modelData.id
                    onClicked: Settings.setStatLabel(tab.kind, modelData.id)
                }
            }
        }

        Text {
            visible: tab.kind === "ram" && tab.mode !== "gauge"
            text: "Значение"
            color: Colors.text
            font.family: Settings.uiFontFamily
            font.pixelSize: 14
            font.bold: true
        }

        RowLayout {
            visible: tab.kind === "ram" && tab.mode !== "gauge"
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: [
                    { id: "gb",  label: "ГиБ" },
                    { id: "pct", label: "Проценты" }
                ]

                BarChip {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    label: modelData.label
                    selected: Settings.ramValue === modelData.id
                    onClicked: Settings.ramValue = modelData.id
                }
            }
        }

        Text {
            visible: tab.kind === "cpu"
            text: "Температура"
            color: Colors.text
            font.family: Settings.uiFontFamily
            font.pixelSize: 14
            font.bold: true
        }

        RowLayout {
            visible: tab.kind === "cpu"
            Layout.fillWidth: true
            spacing: 8

            BarChip {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                label: "Показывать"
                selected: Settings.cpuShowTemp
                onClicked: Settings.cpuShowTemp = true
            }
            BarChip {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                label: "Скрыть"
                selected: !Settings.cpuShowTemp
                onClicked: Settings.cpuShowTemp = false
            }
        }

        Text {
            Layout.fillWidth: true
            text: tab.kind === "cpu"
                  ? "Температура видна, только если система отдаёт датчик процессора. Выше 85 °C она краснеет. Клик по показателю в баре открывает подробное меню."
                  : "Клик по показателю в баре открывает подробное меню памяти."
            wrapMode: Text.WordWrap
            color: Colors.text
            opacity: 0.7
            font.family: Settings.uiFontFamily
            font.pixelSize: 13
        }
    }
}
