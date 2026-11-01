import QtQuick
import ".."

// Подложка одного острова бара (стиль «острова»): «таблетка» вокруг элементов своей зоны.
// Границы приходят от BarItems.zoneSpan; пока зона пуста или стиль «сплошной», остров скрыт.
Rectangle {
    id: island

    property var span: null    // { x, w } в координатах бара или null

    visible: span !== null
    x: span ? span.x : 0
    width: span ? span.w : 0
    height: span ? parent.height : 0
    z: -1
    radius: Settings.barRounded ? height / 2 : 0
    color: Colors[Settings.barColor] ?? Colors.primaryContainer
    border.width: 1
    border.color: Qt.lighter(color, 1.3)

    // Так же плавно, как сдвигаются сами элементы (BarSlot)
    Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
}
