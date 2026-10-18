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
    property string activeTab: "style"
    property string anchorMonitor: ""

    IpcHandler {
        target: "panel"
        function toggle(): void {
            if (!root.shown) root.anchorMonitor = Hyprland.focusedMonitor?.name ?? ""
            root.shown = !root.shown
        }

        // SUPER+Space: открыть панель сразу на вкладке apps (или закрыть, если она уже открыта)
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

            // Когда поиск лаунчера не в фокусе, Esc должен ловить затемнённый фон
            Connections {
                target: root
                function onShownChanged() {
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

                    Loader {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        sourceComponent: root.activeTab === "defaults" ? defaultsTab
                                       : root.activeTab === "apps" ? appsTab
                                       : styleTab
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Repeater {
                            model: ["apps", "defaults", "style"]

                            Rectangle {
                                required property string modelData
                                Layout.fillWidth: true
                                Layout.preferredHeight: 36
                                radius: 999
                                color: root.activeTab === modelData ? Colors.primary : Colors.surfaceContainerHigh

                                Text {
                                    anchors.centerIn: parent
                                    text: parent.modelData
                                    color: root.activeTab === parent.modelData ? Colors.textOnPrimary : Colors.text
                                    font.pixelSize: 14
                                    font.capitalization: Font.Capitalize
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        root.activeTab = parent.modelData
                                        if (parent.modelData !== "apps") dim.forceActiveFocus()
                                    }
                                }
                            }
                        }
                    }
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
                }
            }
        }
    }
}
