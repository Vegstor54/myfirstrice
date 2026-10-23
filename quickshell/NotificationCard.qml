import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts

// Карточка одного уведомления: используется и во всплывающих окнах, и в истории меню.
// Нажатие на карточку вызывает действие по умолчанию приложения (если оно есть) и сворачивает карточку,
// крестик закрывает уведомление совсем.
Rectangle {
    id: card

    required property var notif
    // true — всплывающая карточка (нажатие только убирает её, уведомление остаётся в истории)
    property bool popup: false
    signal activated()

    readonly property bool critical: !!notif && notif.urgency === NotificationUrgency.Critical

    // Путь к значку: картинка из уведомления, иначе значок приложения из темы значков
    readonly property string iconSource: {
        if (!notif) return ""
        if (notif.image !== "") return notif.image
        const name = notif.appIcon
        if (!name) return ""
        if (name.startsWith("/")) return "file://" + name
        return Quickshell.iconPath(name, true)
    }

    implicitHeight: content.implicitHeight + 24
    radius: 20
    color: Qt.rgba(Colors.surfaceContainerHigh.r, Colors.surfaceContainerHigh.g, Colors.surfaceContainerHigh.b, popup ? 0.97 : 1)
    border.width: 1
    border.color: critical ? Colors.error : Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.35)

    // Нажатие на тело карточки (кнопки внутри перехватывают свои клики сами)
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            NotificationState.invokeDefault(card.notif)
            card.activated()
        }
    }

    ColumnLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Значок приложения; без значка — колокольчик
            Item {
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36

                Image {
                    id: iconImg
                    anchors.fill: parent
                    visible: status === Image.Ready
                    source: card.iconSource
                    sourceSize.width: 72
                    sourceSize.height: 72
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                }
                // Нет значка или он не загрузился: кружок с колокольчиком
                Rectangle {
                    anchors.fill: parent
                    visible: iconImg.status !== Image.Ready
                    radius: 18
                    color: Colors.primaryContainer

                    Text {
                        anchors.centerIn: parent
                        text: ""
                        color: Colors.text
                        font.family: "Symbols Nerd Font"
                        font.pixelSize: 16
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: card.notif ? card.notif.appName : ""
                    visible: text !== ""
                    elide: Text.ElideRight
                    color: Colors.text
                    opacity: 0.6
                    font.family: Settings.uiFontFamily
                    font.pixelSize: 11
                }
                Text {
                    Layout.fillWidth: true
                    text: card.notif ? card.notif.summary : ""
                    visible: text !== ""
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                    color: Colors.text
                    font.family: Settings.uiFontFamily
                    font.pixelSize: 14
                    font.bold: true
                }
                Text {
                    Layout.fillWidth: true
                    text: card.notif ? card.notif.body : ""
                    visible: text !== ""
                    wrapMode: Text.Wrap
                    maximumLineCount: card.popup ? 3 : 4
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                    color: Colors.text
                    opacity: 0.85
                    font.family: Settings.uiFontFamily
                    font.pixelSize: 12
                }
            }

            // Крестик: закрыть уведомление совсем (пропадает и из истории)
            Rectangle {
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                radius: 12
                color: closeMouse.containsMouse ? Colors.surfaceContainerHighest : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: ""
                    color: Colors.text
                    opacity: 0.7
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: 12
                }
                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NotificationState.dismiss(card.notif)
                }
            }
        }

        // Кнопки действий; действие по умолчанию («default») отдельной кнопки не получает:
        // оно срабатывает по нажатию на саму карточку
        Flow {
            id: actionsFlow
            Layout.fillWidth: true
            spacing: 8
            visible: actionsRepeater.count > 0

            Repeater {
                id: actionsRepeater
                model: card.notif ? card.notif.actions : []

                Rectangle {
                    id: actionBtn
                    required property var modelData
                    visible: modelData.identifier !== "default"
                    width: visible ? Math.max(72, actionText.implicitWidth + 24) : 0
                    height: visible ? 28 : 0
                    radius: 999
                    color: actionMouse.containsMouse ? Colors.primary : Colors.surfaceContainerHighest

                    Text {
                        id: actionText
                        anchors.centerIn: parent
                        text: actionBtn.modelData.text
                        color: actionMouse.containsMouse ? Colors.textOnPrimary : Colors.text
                        font.family: Settings.uiFontFamily
                        font.pixelSize: 12
                    }
                    MouseArea {
                        id: actionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            actionBtn.modelData.invoke()
                            card.activated()
                        }
                    }
                }
            }
        }
    }
}
