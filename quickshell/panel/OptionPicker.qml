import QtQuick
import QtQuick.Layouts
import ".."

// Выпадающий список: показывает текущее значение, по клику раскрывается список прямо под ним
// (внутри страницы, без всплывающего окна: панель — Overlay с эксклюзивным фокусом).
ColumnLayout {
    id: picker

    property var options: []        // список строк
    property string current: ""     // выбранная строка
    property bool open: false
    signal picked(int index)

    spacing: 4

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 34
        radius: Settings.r(10)
        color: picker.open || headMouse.containsMouse ? Settings.fillActive : Settings.fillHover
        border.width: 0

        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 12
            text: picker.current
            color: Colors.text
            font.family: Settings.uiFontFamily
            font.pixelSize: 13
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 12
            text: picker.open ? "▴" : "▾"
            color: Colors.text
            opacity: 0.7
            font.family: Settings.uiFontFamily
            font.pixelSize: 12
        }
        MouseArea {
            id: headMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: picker.open = !picker.open
        }
    }

    Rectangle {
        visible: picker.open
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(picker.options.length, 6) * 30 + 8
        radius: Settings.r(10)
        color: Settings.fillHover
        border.width: 0

        ListView {
            anchors.fill: parent
            anchors.margins: 4
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: picker.options

            delegate: Rectangle {
                id: opt
                required property string modelData
                required property int index
                readonly property bool selected: modelData === picker.current

                width: ListView.view.width
                height: 30
                radius: Settings.r(8)
                color: selected ? Colors.primary
                     : optMouse.containsMouse ? Settings.fillActive
                     : "transparent"

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    text: opt.modelData
                    color: opt.selected ? Colors.textOnPrimary : Colors.text
                    font.family: Settings.uiFontFamily
                    font.pixelSize: 13
                }
                MouseArea {
                    id: optMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        picker.open = false
                        picker.picked(opt.index)
                    }
                }
            }
        }
    }
}
