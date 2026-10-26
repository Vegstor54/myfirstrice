import QtQuick

// ---- Кнопка группы: значок и необязательная подпись ----
Rectangle {
    id: btn
    property string glyph: ""
    property string label: ""
    property real dim: 1
    property bool active: false
    signal clicked()
    signal middleClicked()
    signal scrolled(int delta)

    height: Settings.barHeight - 12
    width: Math.max(height, content.implicitWidth + 12)
    radius: Settings.barRounded ? height / 2 : 0
    color: active ? Qt.alpha(Colors.text, 0.24)
         : area.containsMouse ? Qt.alpha(Colors.text, 0.16)
         : "transparent"

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 4
        opacity: btn.dim

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: btn.glyph
            color: Colors.text
            font.family: "Symbols Nerd Font"
            font.pixelSize: Math.round(Settings.barHeight * 0.45)
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: btn.label !== ""
            text: btn.label
            color: Colors.text
            font.family: Settings.uiFontFamily
            font.pixelSize: Math.round(Settings.barHeight * 0.4)
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton) btn.middleClicked()
            else btn.clicked()
        }
        onWheel: wheel => btn.scrolled(wheel.angleDelta.y)
    }
}
