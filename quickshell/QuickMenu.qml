import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Меню, которое выезжает из-под бара сверху вниз: уведомления, интернет, звук.
// Открывается кнопками из BarIndicators через toggle(вкладка, монитор).
// Закрывается кликом вне меню или Esc. Бар остаётся кликабельным, поэтому
// вкладки можно переключать и иконками в баре.
Scope {
    id: root

    property bool shown: false
    // "notifications" | "network" | "sound"
    property string tab: "notifications"
    // Имя монитора, на котором открыто меню
    property string monitor: ""

    readonly property var tabs: [
        { id: "notifications", label: "Уведомления" },
        { id: "network",       label: "Интернет" },
        { id: "sound",         label: "Звук" }
    ]

    function toggle(tabId, monitorName) {
        if (shown && tab === tabId && monitor === monitorName) {
            shown = false
            return
        }
        tab = tabId
        monitor = monitorName
        shown = true
    }

    // Блок управления громкостью: заголовок с процентами, слайдер и кнопка выключения.
    // Слайдер: клик и перетаскивание, колесо меняет на 5%.
    component AudioControl: ColumnLayout {
        id: ctl
        property string title: ""
        property real value: 0
        property bool muted: false
        property string muteLabel: ""
        property string mutedLabel: ""
        signal setValue(real v)
        signal step(real d)
        signal toggleMute()

        spacing: 8

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: ctl.title
                color: Colors.text
                font.family: Settings.uiFontFamily
                font.pixelSize: 14
                font.bold: true
            }
            Item { Layout.fillWidth: true }
            Text {
                text: Math.round(ctl.value * 100) + "%"
                color: Colors.text
                font.family: Settings.uiFontFamily
                font.pixelSize: 14
            }
        }

        Item {
            id: slider
            Layout.fillWidth: true
            Layout.preferredHeight: 28

            readonly property real knob: 20

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 8
                radius: 4
                color: Colors.surfaceContainerHighest

                Rectangle {
                    width: ctl.value * (slider.width - slider.knob) + slider.knob / 2
                    height: parent.height
                    radius: 4
                    color: ctl.muted ? Colors.surfaceVariant : Colors.primary
                }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x: ctl.value * (slider.width - slider.knob)
                width: slider.knob
                height: slider.knob
                radius: slider.knob / 2
                color: ctl.muted ? Colors.surfaceVariant : Colors.primary
            }

            MouseArea {
                anchors.fill: parent
                preventStealing: true
                cursorShape: Qt.PointingHandCursor

                function setFrom(mx) {
                    ctl.setValue((mx - slider.knob / 2) / (slider.width - slider.knob))
                }

                onPressed: mouse => setFrom(mouse.x)
                onPositionChanged: mouse => { if (pressed) setFrom(mouse.x) }
                onWheel: wheel => ctl.step(wheel.angleDelta.y > 0 ? 0.05 : -0.05)
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: 999
            color: ctl.muted ? Colors.primary
                 : muteMouse.containsMouse ? Colors.surfaceContainerHighest
                 : Colors.surfaceContainerHigh

            Text {
                anchors.centerIn: parent
                text: ctl.muted ? ctl.mutedLabel : ctl.muteLabel
                color: ctl.muted ? Colors.textOnPrimary : Colors.text
                font.family: Settings.uiFontFamily
                font.pixelSize: 13
            }
            MouseArea {
                id: muteMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: ctl.toggleMute()
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            readonly property bool isTarget: root.monitor === modelData.name

            visible: isTarget && (root.shown || fade.running)
            anchors { top: true; bottom: true; left: true; right: true }
            // Начинается сразу под баром (8 — отступ бара от края), бар остаётся доступным
            margins.top: Settings.barHeight + 8
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

            // Прозрачный фон: клик вне меню закрывает его
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
                // Выезжает сверху вниз: смещение и прозрачность
                property real slide: root.shown ? 0 : -16

                anchors.top: parent.top
                anchors.topMargin: 8 + slide
                anchors.right: parent.right
                anchors.rightMargin: 16
                width: 360
                height: root.tab === "sound" ? 340 : 260
                radius: 24
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

                    // Вкладки
                    RowLayout {
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
                                radius: 999
                                color: selected ? Colors.primary
                                     : tabMouse.containsMouse ? Colors.surfaceContainerHighest
                                     : Colors.surfaceContainerHigh

                                Text {
                                    anchors.centerIn: parent
                                    text: tabChip.modelData.label
                                    color: tabChip.selected ? Colors.textOnPrimary : Colors.text
                                    font.family: Settings.uiFontFamily
                                    font.pixelSize: 12
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

                        // Уведомления: панели пока нет, поэтому заглушка
                        ColumnLayout {
                            anchors.centerIn: parent
                            visible: root.tab === "notifications"
                            spacing: 4

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "Уведомлений нет"
                                color: Colors.text
                                font.family: Settings.uiFontFamily
                                font.pixelSize: 15
                                font.bold: true
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "Здесь появятся уведомления"
                                color: Colors.text
                                opacity: 0.6
                                font.family: Settings.uiFontFamily
                                font.pixelSize: 12
                            }
                        }

                        // Интернет: статус и кнопка настроек
                        ColumnLayout {
                            anchors.fill: parent
                            visible: root.tab === "network"
                            spacing: 16

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                //  — wifi,  — проводное подключение
                                Text {
                                    text: SysState.net === "ethernet" ? "" : ""
                                    color: Colors.text
                                    opacity: SysState.net === "none" ? 0.35 : 1
                                    font.family: "Symbols Nerd Font"
                                    font.pixelSize: 28
                                }
                                ColumnLayout {
                                    spacing: 2
                                    Text {
                                        text: SysState.net === "ethernet" ? "Проводное подключение"
                                            : SysState.net === "wifi" ? "Wi-Fi"
                                            : "Нет подключения"
                                        color: Colors.text
                                        font.family: Settings.uiFontFamily
                                        font.pixelSize: 15
                                        font.bold: true
                                    }
                                    Text {
                                        text: SysState.net === "none" ? "Сеть не найдена" : "Подключено"
                                        color: Colors.text
                                        opacity: 0.6
                                        font.family: Settings.uiFontFamily
                                        font.pixelSize: 12
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 36
                                radius: 999
                                color: netMouse.containsMouse ? Colors.surfaceContainerHighest : Colors.surfaceContainerHigh

                                Text {
                                    anchors.centerIn: parent
                                    text: "Настройки сети"
                                    color: Colors.text
                                    font.family: Settings.uiFontFamily
                                    font.pixelSize: 13
                                }
                                MouseArea {
                                    id: netMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.shown = false
                                        SysState.openNetwork()
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }

                        // Звук: громкость колонок и микрофон
                        ColumnLayout {
                            anchors.fill: parent
                            visible: root.tab === "sound"
                            spacing: 12

                            AudioControl {
                                Layout.fillWidth: true
                                title: "Громкость"
                                value: SysState.volume
                                muted: SysState.muted
                                muteLabel: "Выключить звук"
                                mutedLabel: "Звук выключен"
                                onSetValue: v => SysState.setVolume(v)
                                onStep: d => SysState.changeVolume(d)
                                onToggleMute: SysState.toggleMute()
                            }

                            AudioControl {
                                Layout.fillWidth: true
                                title: "Микрофон"
                                value: SysState.micVolume
                                muted: SysState.micMuted
                                muteLabel: "Выключить микрофон"
                                mutedLabel: "Микрофон выключен"
                                onSetValue: v => SysState.setMicVolume(v)
                                onStep: d => SysState.changeMicVolume(d)
                                onToggleMute: SysState.toggleMicMute()
                            }

                            Item { Layout.fillHeight: true }
                        }
                    }
                }
            }
        }
    }
}
