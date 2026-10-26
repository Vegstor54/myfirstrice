import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

// Лаунчер приложений: поиск + список из .desktop-файлов.
// Enter запускает выбранное, стрелки вверх/вниз двигают выбор, Esc закрывает панель.
ColumnLayout {
    id: tab

    // true, когда вкладка видна и именно на этом мониторе есть клавиатурный фокус
    property bool active: false
    signal closeRequested()
    // Backspace в пустой строке поиска — вернуться в главное меню
    signal backRequested()

    spacing: 12

    readonly property string scripts: Quickshell.env("HOME") + "/.config/quickshell/scripts"

    // Отфильтрованный и отсортированный список приложений
    readonly property var results: {
        const apps = DesktopEntries.applications.values
        const q = searchInput.text.trim().toLowerCase()
        const list = []

        for (let i = 0; i < apps.length; i++) {
            const e = apps[i]
            if (e.noDisplay) continue

            const name = (e.name || "").toLowerCase()
            let score = 0
            if (q === "") score = 1
            else if (name.startsWith(q)) score = 4
            else if (name.indexOf(" " + q) >= 0) score = 3
            else if (name.indexOf(q) >= 0) score = 2
            else {
                const extra = ((e.genericName || "") + " " + Array.from(e.keywords || []).join(" ")).toLowerCase()
                if (extra.indexOf(q) >= 0) score = 1
            }
            if (score > 0) list.push({ entry: e, score: score })
        }

        list.sort((a, b) => (b.score - a.score) || a.entry.name.localeCompare(b.entry.name))
        return list.map(x => x.entry)
    }

    function launch(entry) {
        if (!entry) return
        if (entry.runInTerminal) {
            // TUI-приложения (htop, nvim...) открываем в терминале по умолчанию
            Quickshell.execDetached([tab.scripts + "/run-in-terminal.sh"].concat(Array.from(entry.command)))
        } else {
            entry.execute()
        }
        tab.closeRequested()
    }

    // Двигает выбор стрелками и прокручивает список, чтобы выбранная строка была видна
    function move(delta) {
        const next = Math.max(0, Math.min(list.count - 1, list.currentIndex + delta))
        list.currentIndex = next
        list.positionViewAtIndex(next, ListView.Contain)
    }

    function focusSearch() {
        searchInput.text = ""
        searchInput.forceActiveFocus()
    }

    onActiveChanged: if (active) focusSearch()
    Component.onCompleted: if (active) focusSearch()

    // Строка поиска
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 40
        radius: Settings.r(999)
        color: Colors.surfaceContainerHigh
        border.width: 1
        border.color: searchInput.activeFocus ? Colors.primary : Colors.border

        TextInput {
            id: searchInput
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            verticalAlignment: TextInput.AlignVCenter
            clip: true
            color: Colors.text
            selectionColor: Colors.primary
            selectedTextColor: Colors.textOnPrimary
            font.family: Settings.uiFontFamily
            font.pixelSize: 14

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Down) {
                    tab.move(1)
                    event.accepted = true
                } else if (event.key === Qt.Key_Up) {
                    tab.move(-1)
                    event.accepted = true
                } else if (event.key === Qt.Key_PageDown) {
                    tab.move(8)
                    event.accepted = true
                } else if (event.key === Qt.Key_PageUp) {
                    tab.move(-8)
                    event.accepted = true
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    tab.launch(tab.results[list.currentIndex])
                    event.accepted = true
                } else if (event.key === Qt.Key_Backspace && searchInput.text === ""
                           && searchInput.preeditText === "" && !event.isAutoRepeat) {
                    // isAutoRepeat: зажатый Backspace, стёрший весь текст, не должен выкидывать назад
                    tab.backRequested()
                    event.accepted = true
                } else if (event.key === Qt.Key_Escape) {
                    tab.closeRequested()
                    event.accepted = true
                }
            }

            Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                visible: searchInput.text === "" && searchInput.preeditText === ""
                text: "Поиск приложений…"
                color: Colors.text
                opacity: 0.5
                font.family: Settings.uiFontFamily
                font.pixelSize: 14
            }
        }
    }

    // Список приложений
    ListView {
        id: list
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 2
        model: tab.results
        currentIndex: 0
        highlightFollowsCurrentItem: false
        boundsBehavior: Flickable.StopAtBounds
        // Прокрутка колесом мыши и полоса справа
        ScrollBar.vertical: ScrollBar {
            id: bar
            policy: ScrollBar.AsNeeded
            implicitWidth: 6
            background: Item {}
            contentItem: Rectangle {
                implicitWidth: 6
                radius: Settings.r(3)
                color: Colors.primary
                opacity: bar.pressed ? 0.9 : bar.active ? 0.6 : 0.3
                Behavior on opacity { NumberAnimation { duration: 120 } }
            }
        }

        delegate: Rectangle {
            id: row
            required property var modelData
            required property int index
            readonly property bool selected: ListView.isCurrentItem
            readonly property string iconSource: modelData.icon ? Quickshell.iconPath(modelData.icon, true) : ""

            // справа оставляем место под полосу прокрутки
            width: ListView.view.width - 10
            height: 44
            radius: Settings.r(12)
            color: selected ? Colors.primaryContainer
                 : mouse.containsMouse ? Colors.surfaceContainerHighest
                 : "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 12

                Item {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28

                    Image {
                        id: icon
                        anchors.fill: parent
                        source: row.iconSource
                        sourceSize.width: 56
                        sourceSize.height: 56
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        visible: status === Image.Ready
                    }

                    // Заглушка, если иконка не нашлась
                    Rectangle {
                        anchors.fill: parent
                        radius: Settings.r(8)
                        visible: !icon.visible
                        color: Colors.secondaryContainer

                        Text {
                            anchors.centerIn: parent
                            text: (row.modelData.name || "?").charAt(0).toUpperCase()
                            color: Colors.text
                            font.family: Settings.uiFontFamily
                            font.pixelSize: 14
                            font.bold: true
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: row.modelData.name
                    color: Colors.text
                    font.family: Settings.uiFontFamily
                    font.pixelSize: 14
                    elide: Text.ElideRight
                }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                // positionChanged, а не entered: иначе прокрутка стрелками сбивает выбор
                onPositionChanged: list.currentIndex = row.index
                onClicked: tab.launch(row.modelData)
            }
        }

        Text {
            anchors.centerIn: parent
            visible: tab.results.length === 0
            text: "Ничего не найдено"
            color: Colors.text
            opacity: 0.5
            font.family: Settings.uiFontFamily
            font.pixelSize: 14
        }
    }
}
