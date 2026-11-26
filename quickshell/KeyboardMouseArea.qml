import QtQuick

MouseArea {
    id: area

    property bool keyboardEnabled: true

    activeFocusOnTab: keyboardEnabled
    Keys.enabled: keyboardEnabled

    function moveFocus(forward) {
        const next = area.nextItemInFocusChain(forward)
        if (next && next !== area) next.forceActiveFocus()
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            area.clicked(null)
            event.accepted = true
        } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
            area.moveFocus(true)
            event.accepted = true
        } else if (event.key === Qt.Key_Backtab || event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
            area.moveFocus(false)
            event.accepted = true
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: 10
        color: "transparent"
        border.width: 2
        border.color: "#4f64aa"
        visible: area.activeFocus
        z: 1
    }
}
