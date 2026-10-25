import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// История буфера обмена (Super+V): список из cliphist с поиском.
// Enter или клик кладёт запись обратно в буфер и закрывает меню, Delete удаляет запись,
// стрелки двигают выбор, Esc или клик вне карточки закрывают.
// Нужны пакеты cliphist и wl-clipboard; записи сохраняет автозапуск (wl-paste --watch cliphist store).
Scope {
    id: root

    property bool shown: false
    property string monitor: ""
    property string query: ""
    property int current: 0
    property string error: ""
    // Записи: { line: исходная строка cliphist, text: превью, image: это картинка }
    property var items: []

    readonly property var filtered: {
        const q = query.trim().toLowerCase()
        const r = q === "" ? items : items.filter(e => e.text.toLowerCase().indexOf(q) !== -1)
        return r.slice(0, 200)
    }

    function open() {
        monitor = Hyprland.focusedMonitor?.name ?? Quickshell.screens[0]?.name ?? ""
        query = ""
        current = 0
        refresh()
        shown = true
    }

    function toggle() {
        if (shown) shown = false
        else open()
    }

    function refresh() { lister.running = true }

    function pick(entry) {
        if (!entry) return
        picker.line = entry.line
        picker.running = true
        shown = false
    }

    function remove(entry) {
        if (!entry) return
        remover.line = entry.line
        remover.running = true
        items = items.filter(e => e.line !== entry.line)
        if (current >= filtered.length) current = Math.max(0, filtered.length - 1)
    }

    // quickshell ipc call clipboard toggle
    IpcHandler {
        target: "clipboard"
        function toggle(): void { root.toggle() }
    }

    Process {
        id: lister
        command: ["sh", "-c", "command -v cliphist >/dev/null 2>&1 || exit 127; cliphist list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                for (const line of text.split("\n")) {
                    if (line === "") continue
                    const tab = line.indexOf("\t")
                    const preview = tab >= 0 ? line.slice(tab + 1) : line
                    out.push({ line: line, text: preview, image: preview.indexOf("[[ binary data") === 0 })
                }
                root.items = out
                root.error = ""
            }
        }
        onExited: (code) => {
            if (code === 127) root.error = "Не установлен cliphist: sudo pacman -S cliphist wl-clipboard"
        }
    }

    // Выбранную запись возвращаем в буфер обмена
    Process {
        id: picker
        property string line: ""
        command: ["sh", "-c", "printf '%s\\n' \"$1\" | cliphist decode | wl-copy", "_", line]
    }

    Process {
        id: remover
        property string line: ""
        command: ["sh", "-c", "printf '%s\\n' \"$1\" | cliphist delete", "_", line]
    }

    Process {
        id: wiper
        command: ["cliphist", "wipe"]
        onExited: root.refresh()
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            readonly property bool isTarget: root.monitor === modelData.name

            visible: root.shown || fade.running
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: (root.shown && isTarget) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            Connections {
                target: root
                function onShownChanged() {
                    if (root.shown && win.isTarget) {
                        search.text = ""
                        search.forceActiveFocus()
                    }
                }
            }

            // Затемнённый фон на весь экран: клик вне карточки закрывает меню
            Rectangle {
                anchors.fill: parent
                color: "black"
                opacity: root.shown ? 0.3 : 0
                Behavior on opacity { NumberAnimation { id: fade; duration: 180; easing.type: Easing.OutCubic } }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.shown = false
                }
            }

            Rectangle {
                id: card
                visible: win.isTarget
                anchors.centerIn: parent
                width: 480
                height: 520
                radius: Settings.r(24)
                color: Qt.rgba(Colors.surfaceContainer.r, Colors.surfaceContainer.g, Colors.surfaceContainer.b, 0.95)
                border.width: 1
                border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.35)
                opacity: root.shown ? 1 : 0
                scale: root.shown ? 1 : 0.95

                Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on scale   { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "Буфер обмена"
                            color: Colors.text
                            font.family: Settings.uiFontFamily
                            font.pixelSize: 16
                            font.bold: true
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            width: 92; height: 28; radius: Settings.r(999)
                            color: clearMouse.containsMouse ? Colors.errorContainer : Colors.surfaceContainerHigh
                            visible: root.items.length > 0

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
                                cursorShape: Qt.PointingHandCursor
                                onClicked: wiper.running = true
                            }
                        }
                    }

                    // Поиск
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        radius: Settings.r(999)
                        color: Colors.surfaceContainerHigh

                        TextField {
                            id: search
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            background: null
                            color: Colors.text
                            placeholderText: "Поиск по истории"
                            placeholderTextColor: Qt.rgba(Colors.text.r, Colors.text.g, Colors.text.b, 0.5)
                            font.family: Settings.uiFontFamily
                            font.pixelSize: 14
                            verticalAlignment: TextInput.AlignVCenter
                            text: root.query
                            onTextChanged: {
                                root.query = text
                                root.current = 0
                            }
                            Keys.onEscapePressed: root.shown = false
                            Keys.onDownPressed: {
                                if (root.current < root.filtered.length - 1) root.current++
                                list.positionViewAtIndex(root.current, ListView.Contain)
                            }
                            Keys.onUpPressed: {
                                if (root.current > 0) root.current--
                                list.positionViewAtIndex(root.current, ListView.Contain)
                            }
                            Keys.onReturnPressed: root.pick(root.filtered[root.current])
                            Keys.onEnterPressed: root.pick(root.filtered[root.current])
                            Keys.onDeletePressed: (event) => {
                                // Delete при непустом поиске стирает символы, запись удаляем только когда курсор в конце
                                if (cursorPosition === length) root.remove(root.filtered[root.current])
                                else event.accepted = false
                            }
                        }
                    }

                    ListView {
                        id: list
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 4
                        model: root.filtered
                        boundsBehavior: Flickable.StopAtBounds

                        delegate: Rectangle {
                            id: row
                            required property var modelData
                            required property int index
                            width: list.width
                            height: 40
                            radius: Settings.r(12)
                            color: index === root.current ? Colors.primaryContainer
                                 : rowMouse.containsMouse ? Colors.surfaceContainerHighest
                                 : Colors.surfaceContainerHigh

                            Text {
                                anchors.left: parent.left
                                anchors.right: del.left
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 12
                                anchors.rightMargin: 8
                                text: row.modelData.image ? "Изображение: " + row.modelData.text.replace(/^\[\[ binary data /, "").replace(/ \]\]$/, "") : row.modelData.text
                                elide: Text.ElideRight
                                maximumLineCount: 1
                                color: Colors.text
                                font.family: Settings.uiFontFamily
                                font.pixelSize: 13
                            }

                            MouseArea {
                                id: rowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.pick(row.modelData)
                            }

                            // Кнопка удаления записи
                            Rectangle {
                                id: del
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.rightMargin: 8
                                width: 24; height: 24; radius: Settings.r(12)
                                color: delMouse.containsMouse ? Colors.errorContainer : "transparent"
                                visible: rowMouse.containsMouse || row.index === root.current

                                Text {
                                    anchors.centerIn: parent
                                    text: "×"
                                    color: Colors.text
                                    font.family: Settings.uiFontFamily
                                    font.pixelSize: 16
                                }
                                MouseArea {
                                    id: delMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.remove(row.modelData)
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: root.filtered.length === 0
                            width: parent.width - 32
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            text: root.error !== "" ? root.error
                                : root.query !== "" ? "Ничего не найдено"
                                : "История пока пуста"
                            color: Colors.text
                            opacity: 0.6
                            font.family: Settings.uiFontFamily
                            font.pixelSize: 13
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Enter: вставить в буфер  ·  Delete: удалить  ·  Esc: закрыть"
                        horizontalAlignment: Text.AlignHCenter
                        color: Colors.text
                        opacity: 0.5
                        font.family: Settings.uiFontFamily
                        font.pixelSize: 11
                    }
                }
            }
        }
    }
}
