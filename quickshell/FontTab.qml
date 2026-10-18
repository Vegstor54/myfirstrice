import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Выбор шрифта во всей системе: интерфейс (бар, панель, GTK) или моноширинный (терминал).
// Клик по шрифту сразу применяет его: бар и панель меняются мгновенно,
// остальное пишет scripts/set-font.sh.
ColumnLayout {
    id: tab
    spacing: 12

    // "ui" или "mono"
    property string role: "ui"
    property var uiFonts: []
    property var monoFonts: []

    readonly property string scripts: Quickshell.env("HOME") + "/.config/quickshell/scripts"
    readonly property var fonts: role === "mono" ? monoFonts : uiFonts
    readonly property string current: role === "mono" ? Settings.monoFont : Settings.uiFont

    function apply(family) {
        if (tab.role === "mono") Settings.monoFont = family
        else Settings.uiFont = family
        Quickshell.execDetached([tab.scripts + "/set-font.sh", tab.role, family])
    }

    // Прокручивает список к выбранному шрифту
    function scrollToCurrent() {
        const i = tab.fonts.indexOf(tab.current)
        if (i >= 0) list.positionViewAtIndex(i, ListView.Center)
    }

    onFontsChanged: Qt.callLater(tab.scrollToCurrent)

    Process {
        command: [tab.scripts + "/list-fonts.sh", "ui"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try { tab.uiFonts = JSON.parse(text) }
                catch (e) { console.log("parse error:", e) }
            }
        }
    }

    Process {
        command: [tab.scripts + "/list-fonts.sh", "mono"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try { tab.monoFonts = JSON.parse(text) }
                catch (e) { console.log("parse error:", e) }
            }
        }
    }

    // Переключатель: какой шрифт меняем
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Repeater {
            model: [
                { id: "ui",   label: "Интерфейс" },
                { id: "mono", label: "Моноширинный" }
            ]

            Rectangle {
                id: chip
                required property var modelData
                readonly property bool selected: tab.role === modelData.id

                Layout.fillWidth: true
                Layout.preferredHeight: 36
                radius: 999
                color: selected ? Colors.primary
                     : chipMouse.containsMouse ? Colors.surfaceContainerHighest
                     : Colors.surfaceContainerHigh

                Text {
                    anchors.centerIn: parent
                    text: chip.modelData.label
                    color: chip.selected ? Colors.textOnPrimary : Colors.text
                    font.family: Settings.uiFontFamily
                    font.pixelSize: 13
                }
                MouseArea {
                    id: chipMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: tab.role = chip.modelData.id
                }
            }
        }
    }

    Text {
        Layout.fillWidth: true
        text: tab.role === "mono"
            ? "Терминал (kitty) и моноширинный шрифт GTK"
            : "Бар, панель и GTK-приложения"
        color: Colors.text
        opacity: 0.6
        font.family: Settings.uiFontFamily
        font.pixelSize: 12
        wrapMode: Text.WordWrap
    }

    ListView {
        id: list
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 2
        model: tab.fonts
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            id: bar
            policy: ScrollBar.AsNeeded
            implicitWidth: 6
            background: Item {}
            contentItem: Rectangle {
                implicitWidth: 6
                radius: 3
                color: Colors.primary
                opacity: bar.pressed ? 0.9 : bar.active ? 0.6 : 0.3
                Behavior on opacity { NumberAnimation { duration: 120 } }
            }
        }

        delegate: Rectangle {
            id: row
            required property string modelData
            readonly property bool selected: modelData === tab.current

            // справа оставляем место под полосу прокрутки
            width: ListView.view.width - 10
            height: 40
            radius: 12
            color: selected ? Colors.primary
                 : mouse.containsMouse ? Colors.surfaceContainerHighest
                 : "transparent"

            // Название набрано самим шрифтом, чтобы сразу видеть, как он выглядит
            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                text: row.modelData
                color: row.selected ? Colors.textOnPrimary : Colors.text
                font.family: row.modelData
                font.pixelSize: 15
                elide: Text.ElideRight
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: tab.apply(row.modelData)
            }
        }

        Text {
            anchors.centerIn: parent
            visible: tab.fonts.length === 0
            text: "Шрифты не найдены"
            color: Colors.text
            opacity: 0.5
            font.family: Settings.uiFontFamily
            font.pixelSize: 14
        }
    }
}
