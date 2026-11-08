import QtQuick
import ".."

// Сегментная полоска загрузки: ряд блоков, закрашенных слева направо по проценту.
// Выше 85% закрашенные блоки краснеют. Используется в BarStat.qml, когда выбран вид «Полоса».
Row {
    id: seg

    property real percent: 0          // 0–100
    property int segments: 8
    property int segWidth: Math.max(3, Math.round(Settings.barHeight * 0.16))
    property int segHeight: Math.round(Settings.barHeight * 0.42)

    readonly property int filled: Math.round(Math.max(0, Math.min(100, percent)) / 100 * segments)
    readonly property color fillColor: percent >= 85 ? Colors.error : Colors.text

    spacing: 2

    Repeater {
        model: seg.segments

        Rectangle {
            required property int index
            width: seg.segWidth
            height: seg.segHeight
            radius: 1
            color: index < seg.filled ? seg.fillColor : Qt.alpha(Colors.text, 0.2)
        }
    }
}
