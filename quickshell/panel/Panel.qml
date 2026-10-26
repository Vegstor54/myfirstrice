import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Scope {
    id: root
    property bool shown: false
    // "menu" — главный экран с пунктами, иначе id страницы из pages
    property string activeTab: "menu"
    property string anchorMonitor: ""
    property int menuIndex: 0

    // Пункты главного меню
    readonly property var pages: [
        { id: "apps",     title: "Apps",     subtitle: "Запуск приложений" },
        { id: "control",  title: "Control Center", subtitle: "Сеть, Bluetooth, звук, уведомления" },
        { id: "defaults", title: "Defaults", subtitle: "Приложения по умолчанию" },
        { id: "style",    title: "Style",    subtitle: "Цвета, шрифт, бар и обои" },
        { id: "system",   title: "System",   subtitle: "Сон, гибернация, выключение" }
    ]

    // Пункт с полем action не открывает страницу, а запускает scripts/power.sh <action>.
    // confirm: true — нужно нажать второй раз.
    property string confirming: ""
    onMenuIndexChanged: confirming = ""
    onActiveTabChanged: confirming = ""

    Process {
        id: powerProc
        property string action: ""
        command: [Quickshell.env("HOME") + "/.config/quickshell/scripts/power.sh", action]
    }

    // Вложенные меню: id страницы-меню -> её пункты.
    // id подпункта = "<id родителя>/<имя>", по нему находится родитель при возврате.
    // Новый подпункт: запись здесь + Component и ветка в Loader ниже.
    readonly property var subpages: ({
        // Control Center: те же вкладки, что открывают значки в баре, но доступные и при выключенных модулях
        "control": [
            { id: "control/network",       title: "Интернет",    subtitle: "Статус сети и настройки" },
            { id: "control/bluetooth",     title: "Bluetooth",   subtitle: "Устройства и сопряжение" },
            { id: "control/sound",         title: "Звук",        subtitle: "Громкость, устройства, микрофон" },
            { id: "control/notifications", title: "Уведомления", subtitle: "История и «не беспокоить»" }
        ].filter(i => i.id !== "control/bluetooth" || SysState.hasBluetooth),
        "style": [
            { id: "style/colors", title: "Цветовая схема", subtitle: "Цвет бара" },
            { id: "style/font",   title: "Шрифт",          subtitle: "Шрифт интерфейса и терминала" },
            { id: "style/bar",    title: "Бар",            subtitle: "Размер бара" },
            { id: "style/shape",  title: "Форма",          subtitle: "Скругление бара и интерфейса" },
            { id: "style/modules", title: "Модули бара", subtitle: "Что показывать в баре" },
            { id: "style/wallpaper", title: "Обои",         subtitle: "Картинка рабочего стола и палитра" }
        ],
        "system": [
            { id: "system/suspend",   title: "Сон",         subtitle: "Спящий режим",                    action: "suspend" },
            { id: "system/hibernate", title: "Гибернация",  subtitle: "Сохранить сессию на диск и выключить", action: "hibernate" },
            { id: "system/poweroff",  title: "Выключить",   subtitle: "Выключить компьютер",             action: "poweroff", confirm: true }
        ]
    })

    // Страницы настроек отдельных модулей (шестерёнка на плитке в «Модули бара»): id -> заголовок.
    // Родитель по правилу id — style/modules. Новый модуль: запись здесь + Component и ветка в Loader.
    readonly property var modulePages: ({
        "style/modules/workspaces": "Столы",
        "style/modules/clock": "Часы"
    })

    function itemById(id) {
        const all = pages.concat(...Object.values(subpages))
        for (let i = 0; i < all.length; i++)
            if (all[i].id === id) return all[i]
        return null
    }

    function isMenu(id) { return id === "menu" || subpages[id] !== undefined }

    // Пункты меню с данным id: главное меню или вложенное
    function itemsOf(menuId) { return menuId === "menu" ? pages : (subpages[menuId] ?? []) }

    function parentOf(id) {
        const slash = id.lastIndexOf("/")
        return slash >= 0 ? id.substring(0, slash) : "menu"
    }

    function titleOf(id) {
        const all = pages.concat(...Object.values(subpages))
        for (let i = 0; i < all.length; i++)
            if (all[i].id === id) return all[i].title
        return modulePages[id] ?? ""
    }

    function openPage(id) {
        const item = itemById(id)
        if (item && item.action) {
            if (item.confirm && root.confirming !== id) {
                root.confirming = id
                return
            }
            root.shown = false
            powerProc.action = item.action
            powerProc.running = true
            return
        }
        root.activeTab = id
        if (isMenu(id)) root.menuIndex = 0
    }

    // Назад на уровень выше; курсор остаётся на пункте, откуда пришли
    function back() {
        const parent = parentOf(root.activeTab)
        const items = itemsOf(parent)
        for (let i = 0; i < items.length; i++)
            if (items[i].id === root.activeTab) root.menuIndex = i
        root.activeTab = parent
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
                    } else if (root.isMenu(root.activeTab)) {
                        const items = root.itemsOf(root.activeTab)
                        if (event.key === Qt.Key_Down) {
                            root.menuIndex = (root.menuIndex + 1) % items.length
                            event.accepted = true
                        } else if (event.key === Qt.Key_Up) {
                            root.menuIndex = (root.menuIndex + items.length - 1) % items.length
                            event.accepted = true
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.openPage(items[root.menuIndex].id)
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
                radius: Settings.r(24)
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
                        radius: Settings.r(999)
                        color: backMouse.containsMouse ? Colors.surfaceContainerHighest : Colors.surfaceContainerHigh
                        border.width: 1
                        border.color: Colors.border

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            text: "‹   " + root.titleOf(root.activeTab)
                            color: Colors.text
                            font.family: Settings.uiFontFamily
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
                        sourceComponent: root.isMenu(root.activeTab) ? menuPage
                                       : root.activeTab === "defaults" ? defaultsTab
                                       : root.activeTab === "apps" ? appsTab
                                       : root.activeTab === "control/network" ? networkTab
                                       : root.activeTab === "control/bluetooth" ? bluetoothPage
                                       : root.activeTab === "control/sound" ? soundTab
                                       : root.activeTab === "control/notifications" ? notificationsTab
                                       : root.activeTab === "style/font" ? fontTab
                                       : root.activeTab === "style/bar" ? barTab
                                       : root.activeTab === "style/shape" ? shapeTab
                                       : root.activeTab === "style/modules" ? modulesTab
                                       : root.activeTab === "style/modules/workspaces" ? workspacesSettingsTab
                                       : root.activeTab === "style/modules/clock" ? clockSettingsTab
                                       : root.activeTab === "style/wallpaper" ? wallpaperTab
                                       : colorsTab
                    }
                }
            }

            Component {
                id: menuPage
                ColumnLayout {
                    spacing: 8

                    Repeater {
                        model: root.itemsOf(root.activeTab)

                        Rectangle {
                            id: item
                            required property var modelData
                            required property int index
                            readonly property bool selected: root.menuIndex === index

                            Layout.fillWidth: true
                            Layout.preferredHeight: 56
                            radius: Settings.r(16)
                            color: selected ? Colors.primaryContainer : Colors.surfaceContainerHigh
                            border.width: 1
                            border.color: Colors.border

                            ColumnLayout {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 18
                                spacing: 2

                                Text {
                                    text: item.modelData.title
                                    color: Colors.text
                                    font.family: Settings.uiFontFamily
                                    font.pixelSize: 15
                                    font.bold: true
                                }
                                Text {
                                    readonly property bool asking: root.confirming === item.modelData.id
                                    text: asking ? "Нажми ещё раз для подтверждения" : item.modelData.subtitle
                                    color: asking ? Colors.error : Colors.text
                                    opacity: asking ? 1 : 0.6
                                    font.family: Settings.uiFontFamily
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
                id: networkTab
                NetworkTab {
                    onCloseRequested: root.shown = false
                }
            }

            // Bluetooth грузится по строке и только в окне сфокусированного монитора:
            // окон панели по одному на монитор, два экземпляра вкладки запускали бы поиск дважды
            Component {
                id: bluetoothPage
                Loader {
                    active: win.isFocused && root.shown
                    source: "../tabs/BluetoothTab.qml"
                }
            }

            Component {
                id: soundTab
                SoundTab {}
            }

            Component {
                id: notificationsTab
                NotificationsTab {}
            }

            Component {
                id: fontTab
                FontTab {}
            }

            Component {
                id: barTab
                BarTab {}
            }

            Component {
                id: shapeTab
                ShapeTab {}
            }

            Component {
                id: modulesTab
                ModulesTab {
                    onOpenRequested: moduleId => root.openPage("style/modules/" + moduleId)
                }
            }

            Component {
                id: workspacesSettingsTab
                WorkspacesSettingsTab {}
            }

            Component {
                id: clockSettingsTab
                ClockSettingsTab {}
            }

            Component {
                id: wallpaperTab
                WallpaperTab {
                    onCloseRequested: root.shown = false
                }
            }

            Component {
                id: colorsTab
                ColumnLayout {
                    spacing: 16

                    ThemeModeRow { Layout.fillWidth: true }

                    Text { text: "Цвет бара"; color: Colors.text; font.family: Settings.uiFontFamily }
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
                                width: 36; height: 36; radius: Settings.r(18)
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
