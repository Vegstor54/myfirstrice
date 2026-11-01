import QtQuick
import ".."

// Чип-переключатель для настроек: выбран или нет, по клику сигнал clicked
Rectangle {
    id: chip
    property string label: ""
    property bool selected: false
    // Цвета невыбранного чипа и при наведении: по умолчанию как на карточке панели,
    // на более светлой подложке (строки «Дисплеев») задаются свои
    property color idleColor: Settings.fill
    property color hoverColor: Settings.fillHover
    signal clicked()

    implicitHeight: 36
    radius: Settings.r(999)
    color: selected ? Colors.primary
         : area.containsMouse ? hoverColor
         : idleColor
    border.width: 0

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
