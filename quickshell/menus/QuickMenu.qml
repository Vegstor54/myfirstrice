import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import ".."

// Меню, которое выезжает из-под бара сверху вниз: уведомления, интернет, Bluetooth, звук.
// Открывается кнопками из BarIndicators через toggle(вкладка, монитор).
// Закрывается кликом вне меню (в том числе по «таблетке» в баре) или Esc.
Scope {
    id: root

    property bool shown: false
    // "notifications" | "network" | "bluetooth" | "sound"
    property string tab: "notifications"
    // Имя монитора, на котором открыто меню
    property string monitor: ""
    // Где на экране центр значка, по которому открыли меню: под ним и выезжает карточка
    property real anchorX: 100000

    // Вкладки группы значков, по которой открыли меню; пусто — показывать все
    property var groupTabs: []

    // Вкладка Bluetooth показывается, только если установлен bluez и есть адаптер
    readonly property var tabs: [
        { id: "notifications", label: "Уведомления" },
        { id: "network",       label: "Интернет" },
        { id: "bluetooth",     label: "Bluetooth" },
        { id: "sound",         label: "Звук" }
    ].filter(t => (t.id !== "bluetooth" || SysState.hasBluetooth)
               && (groupTabs.length === 0 || groupTabs.indexOf(t.id) >= 0))

    // Открывает меню на нужной вкладке. Пока меню открыто, фон накрывает и бар,
    // поэтому закрывает его клик куда угодно вне меню; вкладки переключаются кликом по ним.
    function toggle(tabId, monitorName, centerX, tabIds) {
        if (shown && monitor === monitorName) {
            shown = false
            return
        }
        tab = tabId
        monitor = monitorName
        if (centerX !== undefined) anchorX = centerX
        groupTabs = tabIds ?? []
        shown = true
    }

    // Курсор ушёл на другой монитор (Hyprland сменил сфокусированный): закрываем меню.
    // Работает для любого числа мониторов и не зависит от того, дошёл ли клик до перехватчика
    Connections {
        target: Hyprland
        function onFocusedMonitorChanged() {
            if (root.shown && Hyprland.focusedMonitor && Hyprland.focusedMonitor.name !== root.monitor)
                root.shown = false
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            readonly property bool isTarget: root.monitor === modelData.name

            // Окно есть на каждом мониторе: клик вне меню на любом из них закрывает его
            visible: root.shown || fade.running
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: (root.shown && isTarget) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            Connections {
                target: root
                function onShownChanged() {
                    if (root.shown && win.isTarget) catcher.forceActiveFocus()
                }
            }

            // Прозрачный фон на весь экран, в том числе поверх бара:
            // клик вне меню (и по «таблетке» в баре) закрывает его
            Item {
                id: catcher
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: root.shown = false

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.shown = false
                }
            }

            Rectangle {
                id: card
                // Сама карточка рисуется только на целевом мониторе
                visible: win.isTarget
                // Выезжает сверху вниз: смещение и прозрачность
                property real slide: root.shown ? 0 : -16

                anchors.top: parent.top
                // Под баром: 8 — его отступ от края, ещё 8 — зазор до меню
                anchors.topMargin: Settings.barHeight + Settings.barTop + 8 + slide
                // По горизонтали стоит под значком, но не выходит за края экрана
                x: Math.max(Settings.barSideMargin,
                            Math.min(parent.width - width - Settings.barSideMargin, root.anchorX - width / 2))
                width: 400
                height: (root.tab === "sound" ? 520
                        : root.tab === "notifications" ? 440
                        : root.tab === "bluetooth" ? 400 : 260)
                        - (root.tabs.length > 1 ? 0 : 52)
                radius: Settings.r(24)
                color: Qt.rgba(Colors.surfaceContainer.r, Colors.surfaceContainer.g, Colors.surfaceContainer.b, 0.95)
                border.width: 1
                border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.35)
                opacity: root.shown ? 1 : 0

                Behavior on opacity { NumberAnimation { id: fade; duration: 180; easing.type: Easing.OutCubic } }
                Behavior on slide   { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on height  { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                // Клики по карточке не должны закрывать меню
                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 16

                    // Вкладки: у группы из одного значка вкладка одна, ряд не нужен
                    RowLayout {
                        visible: root.tabs.length > 1
                        Layout.fillWidth: true
                        spacing: 8

                        Repeater {
                            model: root.tabs

                            Rectangle {
                                id: tabChip
                                required property var modelData
                                readonly property bool selected: root.tab === modelData.id

                                Layout.fillWidth: true
                                Layout.preferredHeight: 36
                                radius: Settings.r(999)
                                color: selected ? Colors.primary
                                     : tabMouse.containsMouse ? Settings.fillHover
                                     : Settings.fill
                                border.width: 0

                                Text {
                                    anchors.centerIn: parent
                                    text: tabChip.modelData.label
                                    color: tabChip.selected ? Colors.textOnPrimary : Colors.text
                                    font.family: Settings.uiFontFamily
                                    font.pixelSize: 11
                                }
                                MouseArea {
                                    id: tabMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.tab = tabChip.modelData.id
                                }
                            }
                        }
                    }

                    // Содержимое вкладок
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        // Уведомления: «не беспокоить», очистка и история
                        NotificationsTab {
                            anchors.fill: parent
                            visible: root.tab === "notifications"
                        }

                        // Интернет: статус и кнопка настроек
                        NetworkTab {
                            anchors.fill: parent
                            visible: root.tab === "network"
                            onCloseRequested: root.shown = false
                        }

                        // Bluetooth: грузится только при открытой вкладке. Так, если в этой сборке
                        // Quickshell нет модуля Quickshell.Bluetooth, ошибка не ломает всю оболочку
                        Loader {
                            anchors.fill: parent
                            // Только в окне целевого монитора: у меню по окну на каждый монитор,
                            // и два экземпляра вкладки одновременно запускали бы поиск устройств
                            active: win.isTarget && root.shown && root.tab === "bluetooth"
                            source: "../tabs/BluetoothTab.qml"
                        }

                        // Звук: микшер (устройства вывода, приложения, микрофон)
                        SoundTab {
                            anchors.fill: parent
                            visible: root.tab === "sound"
                        }
                    }
                }
            }
        }
    }
}
