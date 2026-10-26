import QtQuick
import QtQuick.Layouts
import ".."

// Строка устройства в списках Bluetooth: имя, подпись и необязательная кнопка справа.
// Не импортирует Quickshell.Bluetooth: данные приходят строками из BluetoothTab.
Rectangle {
    id: row

    property string title: ""
    property string subtitle: ""
    // Подсветка, например для подключённого устройства
    property bool highlighted: false
    // Текст кнопки справа; пусто — кнопки нет
    property string actionLabel: ""
    signal clicked()
    signal actionClicked()

    height: 44
    radius: Settings.r(14)
    color: highlighted ? Colors.primaryContainer
         : rowMouse.containsMouse ? Colors.surfaceContainerHighest
         : Colors.surfaceContainerHigh
    border.width: 1
    border.color: Colors.border

    ColumnLayout {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 14
        anchors.rightMargin: row.actionLabel !== "" ? actionChip.width + 22 : 14
        spacing: 1

        Text {
            Layout.fillWidth: true
            text: row.title
            elide: Text.ElideRight
            color: Colors.text
            font.family: Settings.uiFontFamily
            font.pixelSize: 13
            font.bold: row.highlighted
        }
        Text {
            Layout.fillWidth: true
            text: row.subtitle
            elide: Text.ElideRight
            color: Colors.text
            opacity: 0.6
            font.family: Settings.uiFontFamily
            font.pixelSize: 11
        }
    }

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: row.clicked()
    }

    // Кнопка справа (например, «Забыть»); объявлена после области строки, поэтому ловит клики первой
    Rectangle {
        id: actionChip
        visible: row.actionLabel !== ""
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        width: 72
        height: 28
        radius: Settings.r(999)
        color: actionMouse.containsMouse ? Colors.errorContainer : Colors.surfaceContainer

        Text {
            anchors.centerIn: parent
            text: row.actionLabel
            color: Colors.text
            font.family: Settings.uiFontFamily
            font.pixelSize: 12
        }
        MouseArea {
            id: actionMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: row.actionClicked()
        }
    }
}
