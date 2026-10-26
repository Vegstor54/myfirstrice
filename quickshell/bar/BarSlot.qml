import QtQuick
import ".."

// Обёртка элемента бара: его можно схватить мышью и перетащить (логика в BarItems.qml).
// Обычный клик доходит до содержимого; перетаскивание начинается, когда мышь сдвинули
// на несколько пикселей, и тогда DragHandler забирает жест у кнопок внутри.
Item {
    id: slot

    required property string key
    required property var host

    default property alias content: holder.data

    readonly property bool dragging: host.dragKey === key

    width: holder.childrenRect.width
    height: host.height
    z: dragging ? 10 : 0
    opacity: dragging ? 0.85 : 1

    // Над этим элементом завис другой значок: он «раскрывается» и готов принять его в группу
    scale: host.mergeTarget === key ? 1.15 : dragging && host.mergeTarget !== "" ? 0.85 : 1
    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

    // Какой значок группы стоит под x (в координатах элемента); для вытаскивания из группы
    function moduleAt(x) {
        const c = holder.children[0]
        return c && c.moduleAt ? c.moduleAt(x) : ""
    }

    // Остальные элементы плавно сдвигаются; сам перетаскиваемый идёт строго за мышью
    x: dragging ? host.dragX : host.layoutX(key)
    Behavior on x {
        enabled: !slot.dragging
        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
    }

    Item {
        id: holder
        width: childrenRect.width
        height: slot.height
    }

    DragHandler {
        target: null
        xAxis.enabled: true
        yAxis.enabled: true
        onActiveChanged: {
            if (active) slot.host.beginDrag(slot, centroid.pressPosition.x)
            else slot.host.endDrag()
        }
        onTranslationChanged: {
            if (active) slot.host.dragMoved(translation.x, translation.y)
        }
    }
}
