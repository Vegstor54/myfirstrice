import QtQuick
import QtQuick.Layouts

// Список пунктов меню: items = [{ page: "...", title: "..." }], клик отправляет chosen(page)
ColumnLayout {
    id: menu

    property var items: []
    signal chosen(string page)

    spacing: 8

    Repeater {
        model: menu.items

        Rectangle {
            id: item
            required property var modelData

            Layout.fillWidth: true
            Layout.preferredHeight: 52
            radius: 16
            color: mouse.containsMouse ? Colors.surfaceContainerHighest : Colors.surfaceContainerHigh

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                text: item.modelData.title
                color: Colors.text
                font.pixelSize: 15
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                text: "›"
                color: Colors.text
                opacity: 0.5
                font.pixelSize: 18
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: menu.chosen(item.modelData.page)
            }
        }
    }

    Item { Layout.fillHeight: true }
}
