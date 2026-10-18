import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Scope {
    id: root
    property bool shown: false
    property string anchorMonitor: ""
    // Режим лаунчера (SUPER+Space): только список приложений, без шапки и навигации
    property bool launcherMode: false

    // --- Навигация -----------------------------------------------------------
    // page — текущая страница, history — стек пройденных страниц (для Backspace).
    property string page: "home"
    property var history: []

    // Страницы-меню: список пунктов, клик по пункту открывает страницу page.
    // Чтобы добавить подпункт, допиши его сюда, в titles и создай Component ниже.
    readonly property var menus: ({
        "home": [
            { page: "apps",     title: "Приложения" },
            { page: "defaults", title: "Программы по умолчанию" },
            { page: "custom",   title: "Кастомизация" }
        ],
        "custom": [
            { page: "custom/bar", title: "Цвет бара" }
        ]
    })

    readonly property var titles: ({
        "apps":       "Приложения",
        "defaults":   "Программы по умолчанию",
        "custom":     "Кастомизация",
        "custom/bar": "Цвет бара"
    })

    function open(name) {
        root.history = root.history.concat([root.page])
        root.page = name
    }

    function back() {
        if (root.history.length === 0) return
        root.page = root.history[root.history.length - 1]
        root.history = root.history.slice(0, -1)
    }

    function reset(name) {
        root.history = []
        root.page = name
    }

    IpcHandler {
        target: "panel"
        function toggle(): void {
            if (!root.shown) {
                root.anchorMonitor = Hyprland.focusedMonitor?.name ?? ""
                root.launcherMode = false
                root.reset("home")
            }
            root.shown = !root.shown
        }

        // SUPER+Space: открыть лаунчер (или закрыть, если он уже открыт)
        function launcher(): void {
            if (root.shown && root.launcherMode) {
                root.shown = false
                return
            }
            if (!root.shown) root.anchorMonitor = Hyprland.focusedMonitor?.name ?? ""
            root.launcherMode = true
            root.reset("apps")
            root.shown = true
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            readonly property bool isFocused: root.anchorMonitor === modelData.name

            visible: root.shown || fade.running
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: (root.shown && isFocused) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            // Пока поиск лаунчера не в фокусе, Esc и Backspace должен ловить затемнённый фон
            Connections {
                target: root
                function onShownChanged() {
                    if (root.shown && win.isFocused && root.page !== "apps") dim.forceActiveFocus()
                }
                function onPageChanged() {
                    if (root.shown && win.isFocused && root.page !== "apps") dim.forceActiveFocus()
                }
            }

            Rectangle {
                id: dim
                anchors.fill: parent
                color: "black"
                opacity: root.shown ? 0.3 : 0
                focus: true

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        root.shown = false
                        event.accepted = true
                    } else if (event.key === Qt.Key_Backspace && !event.isAutoRepeat) {
                        root.back()
                        event.accepted = true
                    }
                }

                Behavior on opacity { NumberAnimation { id: fade; duration: 180; easing.type: Easing.OutCubic } }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.shown = false
                }
            }

            Rectangle {
                id: card
                visible: win.isFocused
                anchors.centerIn: parent
                width: 384
                height: 544
                radius: 24
                color: Qt.rgba(Colors.surfaceContainer.r, Colors.surfaceContainer.g, Colors.surfaceContainer.b, 0.92)
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
                    spacing: 16

                    // Шапка: кнопка «назад» и название страницы (на главной и в лаунчере её нет)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        visible: !root.launcherMode && root.page !== "home"

                        Rectangle {
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 36
                            radius: 18
                            color: backMouse.containsMouse ? Colors.surfaceContainerHighest : Colors.surfaceContainerHigh

                            Text {
                                anchors.centerIn: parent
                                text: "←"
                                color: Colors.text
                                font.pixelSize: 16
                            }
                            MouseArea {
                                id: backMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.back()
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.titles[root.page] ?? ""
                            color: Colors.text
                            font.pixelSize: 16
                            font.bold: true
                            elide: Text.ElideRight
                        }
                    }

                    Loader {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        sourceComponent: root.page === "apps" ? appsTab
                                       : root.page === "defaults" ? defaultsTab
                                       : root.page === "custom/bar" ? barTab
                                       : menuTab
                    }
                }
            }

            // Страница-меню (главная и «Кастомизация»): список пунктов из root.menus
            Component {
                id: menuTab
                MenuList {
                    items: root.menus[root.page] ?? []
                    onChosen: name => root.open(name)
                }
            }

            Component {
                id: barTab
                ColumnLayout {
                    spacing: 16

                    GridLayout {
                        columns: 6
                        columnSpacing: 8
                        rowSpacing: 8

                        Repeater {
                            model: ["primary", "primaryContainer", "secondary", "secondaryContainer",
                                    "tertiary", "tertiaryContainer", "surface", "surfaceVariant",
                                    "surfaceContainer", "surfaceContainerHigh", "surfaceContainerHighest",
                                    "error", "errorContainer"]

                            Rectangle {
                                required property string modelData
                                width: 36; height: 36; radius: 18
                                color: Colors[modelData]
                                border.width: Settings.barColor === modelData ? 3 : 1
                                border.color: Settings.barColor === modelData ? Colors.text : Qt.darker(color, 1.3)

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: Settings.barColor = parent.modelData
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }

            Component {
                id: defaultsTab
                ColumnLayout {
                    spacing: 16
                    DefaultsRow { label: "Terminal";     category: "terminal" }
                    DefaultsRow { label: "File Manager"; category: "filemanager" }
                    DefaultsRow { label: "Browser";      category: "browser" }
                    DefaultsRow { label: "Editor";       category: "editor" }
                    Item { Layout.fillHeight: true }
                }
            }

            Component {
                id: appsTab
                AppsTab {
                    active: root.shown && win.isFocused && root.page === "apps"
                    // В лаунчере Backspace только стирает текст, назад идти некуда
                    allowBack: !root.launcherMode
                    onCloseRequested: root.shown = false
                    onBackRequested: root.back()
                }
            }
        }
    }
}
