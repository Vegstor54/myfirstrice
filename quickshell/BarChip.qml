import QtQuick

// Чип-переключатель для настроек: выбран или нет, по клику сигнал clicked
Rectangle {
    id: chip
    property string label: ""
    property bool selected: false
    signal clicked()

    implicitHeight: 36
    radius: 999
    color: selected ? Colors.primary
         : area.containsMouse ? Colors.surfaceContainerHighest
         : Colors.surfaceContainerHigh

    Text {
        anchors.centerIn: parent
        text: chip.label
        color: chip.selected ? Colors.textOnPrimary : Colors.text
        font.family: Settings.uiFontFamily
        font.pixelSize: 13
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: chip.clicked()
    }
}
