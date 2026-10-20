import QtQuick

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
        yAxis.enabled: false
        onActiveChanged: {
            if (active) slot.host.beginDrag(slot)
            else slot.host.endDrag()
        }
        onTranslationChanged: {
            if (active) slot.host.dragMoved(slot, translation.x)
        }
    }
}
