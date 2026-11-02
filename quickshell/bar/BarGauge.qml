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
    readonly property real lineWidth: Math.max(3, Math.round(ringSize * 0.14))
    // Выше 85% дуга краснеет
    readonly property color fillColor: percent >= 85 ? Colors.error : Colors.text

    width: ringSize + 6 + labels.implicitWidth + 12
    height: Settings.barHeight

    onPercentChanged: ring.requestPaint()
    onFillColorChanged: ring.requestPaint()

    Canvas {
        id: ring
        width: gauge.ringSize
        height: gauge.ringSize
        x: 6
        anchors.verticalCenter: parent.verticalCenter
        antialiasing: true

        // Дуга плавно догоняет значение, а не прыгает раз в две секунды
        property real shown: gauge.percent
        Behavior on shown { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        onShownChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const c = width / 2
            const r = c - gauge.lineWidth / 2
            // Спидометр: от 135° (внизу слева) по часовой на 270° до 45° (внизу справа)
            const start = Math.PI * 0.75
            const span = Math.PI * 1.5
            ctx.lineWidth = gauge.lineWidth
            ctx.lineCap = "round"

            ctx.strokeStyle = Qt.alpha(Colors.text, 0.2)
            ctx.beginPath()
            ctx.arc(c, c, r, start, start + span, false)
            ctx.stroke()

            const frac = Math.max(0, Math.min(1, shown / 100))
            if (frac > 0.005) {
                ctx.strokeStyle = gauge.fillColor
                ctx.beginPath()
                ctx.arc(c, c, r, start, start + span * frac, false)
                ctx.stroke()
            }
        }

        Text {
            anchors.centerIn: parent
            text: Math.round(gauge.percent)
            color: Colors.text
            font.family: Settings.uiFontFamily
            font.pixelSize: Math.round(gauge.ringSize * 0.38)
            font.bold: true
        }
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
