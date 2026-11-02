import QtQuick
import ".."

// Кольцевой индикатор загрузки, «спидометр» без стрелки: дуга в 270° (разрыв внизу) заполняется
// слева направо по мере роста значения, в центре число. Справа подпись и подробность (для памяти — ГиБ).
// Используется в BarStat.qml, когда включён вид «Кольцо» (Settings.statStyle).
Item {
    id: gauge

    property string label: "CPU"
    property real percent: 0          // 0–100
    property string detail: ""        // вторая строка справа, например «5.2G»; пусто — только подпись

    readonly property int ringSize: Settings.barHeight - 6
    width: ringSize + 6 + labels.implicitWidth + 12
    height: Settings.barHeight

    GaugeRing {
        x: 6
        anchors.verticalCenter: parent.verticalCenter
        size: gauge.ringSize
        percent: gauge.percent
    }

    Column {
        id: labels
        x: 6 + gauge.ringSize + 6
        anchors.verticalCenter: parent.verticalCenter
        spacing: -1

        Text {
            text: gauge.label
            color: Colors.text
            opacity: 0.7
            font.family: Settings.uiFontFamily
            font.pixelSize: Math.round(Settings.barHeight * 0.32)
        }
        Text {
            visible: gauge.detail !== ""
            // Ширина по самому широкому значению, чтобы бар не дёргался
            width: Math.max(implicitWidth, detailMetrics.width)
            text: gauge.detail
            color: Colors.text
            font.family: Settings.uiFontFamily
            font.pixelSize: Math.round(Settings.barHeight * 0.36)
            font.bold: true
        }
    }

    TextMetrics {
        id: detailMetrics
        font.family: Settings.uiFontFamily
        font.pixelSize: Math.round(Settings.barHeight * 0.36)
        font.bold: true
        text: gauge.detail !== "" ? "99.9G" : ""
    }
}
