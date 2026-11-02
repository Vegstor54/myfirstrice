import QtQuick
import ".."

// Кольцо-«спидометр» без стрелки: дуга в 270° (разрыв внизу) заполняется слева направо, в центре число.
// Общий для маленького кольца в баре (BarGauge.qml) и большого в меню (StatMenu.qml).
Canvas {
    id: ring

    property real percent: 0          // 0–100
    property int size: 26
    property real lineWidth: Math.max(3, Math.round(size * 0.14))
    property real numberScale: 0.38   // размер числа относительно кольца
    // Выше 85% дуга краснеет
    readonly property color fillColor: percent >= 85 ? Colors.error : Colors.text

    width: size
    height: size
    antialiasing: true

    // Дуга плавно догоняет значение, а не прыгает раз в две секунды
    property real shown: percent
    Behavior on shown { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
    onShownChanged: requestPaint()
    onFillColorChanged: requestPaint()
    onSizeChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const c = width / 2
        const r = c - lineWidth / 2
        // От 135° (внизу слева) по часовой на 270° до 45° (внизу справа)
        const start = Math.PI * 0.75
        const span = Math.PI * 1.5
        ctx.lineWidth = lineWidth
        ctx.lineCap = "round"

        ctx.strokeStyle = Qt.alpha(Colors.text, 0.2)
        ctx.beginPath()
        ctx.arc(c, c, r, start, start + span, false)
        ctx.stroke()

        const frac = Math.max(0, Math.min(1, shown / 100))
        if (frac > 0.005) {
            ctx.strokeStyle = fillColor
            ctx.beginPath()
            ctx.arc(c, c, r, start, start + span * frac, false)
            ctx.stroke()
        }
    }

    Text {
        anchors.centerIn: parent
        text: Math.round(ring.percent)
        color: Colors.text
        font.family: Settings.uiFontFamily
        font.pixelSize: Math.round(ring.size * ring.numberScale)
        font.bold: true
    }
}
