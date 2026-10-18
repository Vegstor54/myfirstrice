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
    // "menu" — главный экран с пунктами, иначе id страницы из pages
    property string activeTab: "menu"
    property string anchorMonitor: ""
    property int menuIndex: 0

    readonly property var pages: [
        { id: "apps",     title: "Apps",     subtitle: "Запуск приложений" },
        { id: "defaults", title: "Defaults", subtitle: "Приложения по умолчанию" },
        { id: "style",    title: "Style",    subtitle: "Цвета и оформление" }
    ]

    function titleOf(id) {
        for (let i = 0; i < pages.length; i++)
            if (pages[i].id === id) return pages[i].title
        return ""
    }

    function openPage(id) { root.activeTab = id }

    // Назад в главное меню; курсор остаётся на странице, откуда пришли
    function back() {
        for (let i = 0; i < pages.length; i++)
            if (pages[i].id === root.activeTab) root.menuIndex = i
        root.activeTab = "menu"
    }

    IpcHandler {
        target: "panel"

        // SUPER+S: главное меню панели
        function toggle(): void {
            if (!root.shown) {
                root.anchorMonitor = Hyprland.focusedMonitor?.name ?? ""
                root.activeTab = "menu"
                root.menuIndex = 0
            }
            root.shown = !root.shown
        }

        // SUPER+Space: сразу страница Apps (или закрыть, если она уже открыта)
        function launcher(): void {
            if (root.shown && root.activeTab === "apps") {
                root.shown = false
                return
            }
            if (!root.shown) root.anchorMonitor = Hyprland.focusedMonitor?.name ?? ""
            root.activeTab = "apps"
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

            // Вне страницы Apps (там фокус у строки поиска) клавиши ловит затемнённый фон
            Connections {
                target: root
                function onShownChanged() {
                    if (root.shown && win.isFocused && root.activeTab !== "apps") dim.forceActiveFocus()
                }
                function onActiveTabChanged() {
                    if (root.shown && win.isFocused && root.activeTab !== "apps") dim.forceActiveFocus()
                }
            }

            Rectangle {
                id: dim
                anchors.fill: parent
                color: "black"
                opacity: root.shown ? 0.3 : 0
                focus: true

                Keys.onEscapePressed: root.shown = false
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Backspace) {
                        if (root.activeTab !== "menu" && !event.isAutoRepeat) root.back()
                        event.accepted = true
                    } else if (root.activeTab === "menu") {
                        if (event.key === Qt.Key_Down) {
                            root.menuIndex = (root.menuIndex + 1) % root.pages.length
                            event.accepted = true
                        } else if (event.key === Qt.Key_Up) {
                            root.menuIndex = (root.menuIndex + root.pages.length - 1) % root.pages.length
                            event.accepted = true
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.openPage(root.pages[root.menuIndex].id)
                            event.accepted = true
                        }
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

                    // Шапка страницы: «назад» и название (на главном экране её нет)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        visible: root.activeTab !== "menu"
                        radius: 999
                        color: backMouse.containsMouse ? Colors.surfaceContainerHighest : Colors.surfaceContainerHigh

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            text: "‹   " + root.titleOf(root.activeTab)
                            color: Colors.text
                            font.pixelSize: 14
                            font.bold: true
                        }
                        MouseArea {
                            id: backMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.back()
                        }
                    }

                    Loader {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        sourceComponent: root.activeTab === "menu" ? menuPage
                                       : root.activeTab === "defaults" ? defaultsTab
                                       : root.activeTab === "apps" ? appsTab
                                       : styleTab
                    }
                }
            }

            Component {
                id: menuPage
                ColumnLayout {
                    spacing: 8

                    Repeater {
                        model: root.pages

                        Rectangle {
                            id: item
                            required property var modelData
                            required property int index
                            readonly property bool selected: root.menuIndex === index

                            Layout.fillWidth: true
                            Layout.preferredHeight: 56
                            radius: 16
                            color: selected ? Colors.primaryContainer : Colors.surfaceContainerHigh

                            ColumnLayout {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 18
                                spacing: 2

                                Text {
                                    text: item.modelData.title
                                    color: Colors.text
                                    font.pixelSize: 15
                                    font.bold: true
                                }
                                Text {
                                    text: item.modelData.subtitle
                                    color: Colors.text
                                    opacity: 0.6
                                    font.pixelSize: 12
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onPositionChanged: root.menuIndex = item.index
                                onClicked: root.openPage(item.modelData.id)
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }

            Component {
                id: styleTab
                ColumnLayout {
                    spacing: 16

                    Text { text: "Цвет бара"; color: Colors.text }
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
                    active: root.shown && win.isFocused && root.activeTab === "apps"
                    onCloseRequested: root.shown = false
                    onBackRequested: root.back()
                }
            }
        }
    }
}
