import QtQuick
import QtQuick.Layouts

// Вкладка «Уведомления» в выезжающем меню: «не беспокоить», «очистить» и история уведомлений.
ColumnLayout {
    id: tab
    spacing: 12

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        // Не беспокоить: всплывающие карточки не показываются (срочные всё равно показываются)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: 999
            color: NotificationState.dnd ? Colors.primary
                 : dndMouse.containsMouse ? Colors.surfaceContainerHighest
                 : Colors.surfaceContainerHigh

            Row {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    // bell-slash, когда режим включён, иначе колокольчик
                    text: NotificationState.dnd ? "" : ""
                    color: NotificationState.dnd ? Colors.textOnPrimary : Colors.text
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: 13
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: NotificationState.dnd ? "Не беспокоить: вкл" : "Не беспокоить"
                    color: NotificationState.dnd ? Colors.textOnPrimary : Colors.text
                    font.family: Settings.uiFontFamily
                    font.pixelSize: 12
                }
            }
            MouseArea {
                id: dndMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: NotificationState.toggleDnd()
            }
        }

        Rectangle {
            Layout.preferredWidth: 96
            Layout.preferredHeight: 32
            radius: 999
            opacity: NotificationState.count > 0 ? 1 : 0.4
            color: clearMouse.containsMouse && NotificationState.count > 0
                   ? Colors.surfaceContainerHighest : Colors.surfaceContainerHigh

            Text {
                anchors.centerIn: parent
                text: "Очистить"
                color: Colors.text
                font.family: Settings.uiFontFamily
                font.pixelSize: 12
            }
            MouseArea {
                id: clearMouse
                anchors.fill: parent
                hoverEnabled: true
                enabled: NotificationState.count > 0
                cursorShape: Qt.PointingHandCursor
                onClicked: NotificationState.clearAll()
            }
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        // Пусто
        ColumnLayout {
            anchors.centerIn: parent
            visible: NotificationState.count === 0
            spacing: 4

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Уведомлений нет"
                color: Colors.text
                font.family: Settings.uiFontFamily
                font.pixelSize: 15
                font.bold: true
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Здесь появятся уведомления"
                color: Colors.text
                opacity: 0.6
                font.family: Settings.uiFontFamily
                font.pixelSize: 12
            }
        }

        ListView {
            id: list
            anchors.fill: parent
            visible: NotificationState.count > 0
            clip: true
            spacing: 8
            model: NotificationState.history

            delegate: NotificationCard {
                required property var modelData
                notif: modelData
                width: list.width
            }
        }
    }
}
