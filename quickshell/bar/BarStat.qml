import QtQuick
import ".."

// Показатель системы в баре: значок и значение. kind: "ram" — занятая память, "cpu" — загрузка процессора.
// Данные собирает state/SysStats.qml (опрос идёт, пока включён хотя бы один из этих модулей).
Item {
    id: stat

    property string kind: "cpu"
    // Меню с подробностями (StatMenu.qml) и имя монитора бара: клик открывает его под показателем
    property var menu: null
    property string screenName: ""

    readonly property int fontSize: Math.round(Settings.barHeight * 0.45)

    // Вид из настроек модуля (страница модуля в «Модули бара»): "text", "gauge" или "bar"
    readonly property string mode: Settings.statMode(kind)
    readonly property bool ring: mode === "gauge"
    readonly property bool segments: mode === "bar"
    // Что стоит перед значением: "icon", "text" (подпись cpu / ram) или "none"
    readonly property string label: Settings.statLabel(kind)
    readonly property real percent: kind === "ram" ? SysStats.ramPct : SysStats.cpu
    readonly property bool ramPercent: kind === "ram" && Settings.ramValue === "pct"
    readonly property string valueText: kind === "cpu" ? SysStats.cpuText
                                      : ramPercent ? SysStats.ramPct + "%" : SysStats.ramText

    // Температура показывается рядом с загрузкой CPU, пока датчик найден и она не выключена в настройках
    readonly property bool showTemp: kind === "cpu" && SysStats.hasTemp && Settings.cpuShowTemp

    width: ring ? gaugeView.width : row.implicitWidth + 12
    height: Settings.barHeight

    // Вид «Кольцо»: дуга-спидометр с числом в центре
    BarGauge {
        id: gaugeView
        visible: stat.ring
        anchors.verticalCenter: parent.verticalCenter
        label: stat.kind === "ram" ? "RAM" : "CPU"
        percent: stat.kind === "ram" ? SysStats.ramPct : SysStats.cpu
        detail: stat.kind === "ram" ? SysStats.ramText : (stat.showTemp ? SysStats.cpuTempText : "")
        hot: stat.kind === "cpu" && SysStats.cpuTemp >= 85
    }

    // Ширина значения не прыгает от «7%» к «10%»: берётся по самому широкому значению
    TextMetrics {
        id: metrics
        font.family: Settings.uiFontFamily
        font.pixelSize: stat.fontSize
        text: stat.kind === "ram" && !stat.ramPercent ? "99.9G" : "100%"
    }

    TextMetrics {
        id: tempMetrics
        font.family: Settings.uiFontFamily
        font.pixelSize: stat.fontSize
        text: "100°C"
    }

    Row {
        id: row
        visible: !stat.ring
        anchors.centerIn: parent
        spacing: 6

        // Значок памяти нарисован (планка с контактами), чтобы не зависеть от шрифта
        Item {
            visible: stat.kind === "ram" && stat.label === "icon"
            width: 16
            height: 10
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                anchors.fill: parent
                radius: 2
                color: "transparent"
                border.width: 1.5
                border.color: Colors.text
            }
            Row {
                anchors.centerIn: parent
                spacing: 2
                Repeater {
                    model: 3
                    Rectangle { width: 2; height: 4; color: Colors.text }
                }
            }
        }

        // Значок процессора: глиф Nerd Font «microchip» (U+F2DB)
        Text {
            visible: stat.kind === "cpu" && stat.label === "icon"
            anchors.verticalCenter: parent.verticalCenter
            text: ""
            color: Colors.text
            font.family: "Symbols Nerd Font"
            font.pixelSize: stat.fontSize
        }

        // Текстовая подпись вместо значка
        Text {
            visible: stat.label === "text"
            anchors.verticalCenter: parent.verticalCenter
            text: stat.kind
            color: Colors.text
            opacity: 0.7
            font.family: Settings.uiFontFamily
            font.pixelSize: stat.fontSize
        }

        // Вид «Полоса»: сегментная полоска загрузки
        SegmentBar {
            visible: stat.segments
            anchors.verticalCenter: parent.verticalCenter
            percent: stat.percent
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: metrics.width
            text: stat.valueText
            color: Colors.text
            font.family: Settings.uiFontFamily
            font.pixelSize: stat.fontSize
        }

        // Температура процессора: выше 85 °C красным
        Text {
            visible: stat.showTemp
            anchors.verticalCenter: parent.verticalCenter
            width: tempMetrics.width
            text: SysStats.cpuTempText
            color: SysStats.cpuTemp >= 85 ? Colors.error : Colors.text
            opacity: SysStats.cpuTemp >= 85 ? 1 : 0.75
            font.family: Settings.uiFontFamily
            font.pixelSize: stat.fontSize
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: stat.menu?.toggle(stat.kind, stat.screenName, stat.mapToItem(null, stat.width / 2, 0).x)
    }
}
