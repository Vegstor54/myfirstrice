import Quickshell
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

// Модуль бара «Трей»: значки приложений (StatusNotifierItem: nm-applet, Discord, Steam, Telegram...).
// Левая кнопка — действие приложения, средняя — второе действие, правая — его меню.
// Меню приложения рисуется здесь же, в цветах темы (а не нативным меню Qt): пункты, разделители,
// галочки и подменю (подменю открывается на месте, сверху строка «назад»).
// Грузится через Loader и в qmldir не регистрируется: если в этой сборке Quickshell нет
// модуля Quickshell.Services.SystemTray, ломается только он, а не весь бар.
Rectangle {
    id: pill

    readonly property int count: SystemTray.items.values.length
    readonly property int iconSize: Math.round(Settings.barHeight * 0.55)

    // Элемент трея, меню которого сейчас открыто (null — никакое): открытым бывает только одно меню
    property var openItem: null

    height: Settings.barHeight - 8
    width: row.implicitWidth + 12
    radius: height / 2
    color: Qt.rgba(1, 1, 1, 0.10)

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Repeater {
            model: SystemTray.items

            MouseArea {
                id: area
                required property var modelData

                width: pill.iconSize
                height: pill.iconSize
                anchors.verticalCenter: parent.verticalCenter
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

                // Показывает меню под значком: запоминает центр значка по горизонтали (в координатах экрана)
                function openMenu() {
                    if (pill.openItem === area.modelData) { pill.openItem = null; return }
                    popup.stack = []
                    popup.anchorX = area.mapToItem(null, area.width / 2, 0).x + Settings.barSideMargin
                    pill.openItem = area.modelData
                }

                onClicked: ev => {
                    if (ev.button === Qt.RightButton) {
                        if (modelData.hasMenu) openMenu()
                    } else if (ev.button === Qt.MiddleButton) {
                        modelData.secondaryActivate()
                    } else if (modelData.onlyMenu && modelData.hasMenu) {
                        openMenu()
                    } else {
                        modelData.activate()
                    }
                }

                IconImage {
                    anchors.fill: parent
                    source: area.modelData.icon
                    opacity: area.containsMouse ? 1 : 0.85
                }

                QsMenuOpener {
                    id: opener
                    menu: popup.current
                }

                // Окно меню: прозрачный слой на весь экран ниже бара, как у QuickMenu. Любой клик
                // вне карточки (по окнам, обоям) закрывает меню; сам бар остаётся кликабельным,
                // поэтому клик по другому значку трея сразу переключает меню.
                PanelWindow {
                    id: popup

                    // Центр значка по горизонтали в координатах экрана
                    property real anchorX: 0

                    // Открытые подменю (самое глубокое последним); пусто — корневое меню приложения
                    property var stack: []
                    readonly property var current:
                        stack.length > 0 ? stack[stack.length - 1] : area.modelData.menu

                    visible: pill.openItem === area.modelData
                    screen: area.QsWindow.window ? area.QsWindow.window.screen : null
                    anchors { top: true; bottom: true; left: true; right: true }
                    // Бар сверху остаётся свободным: 8 — отступ бара от края экрана
                    margins.top: 8 + Settings.barHeight
                    color: "transparent"
                    exclusionMode: ExclusionMode.Ignore
                    WlrLayershell.layer: WlrLayer.Overlay
                    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                        onPressed: pill.openItem = null
                    }

                    Rectangle {
                        id: card
                        width: implicitWidth
                        height: implicitHeight
                        y: 6
                        x: Math.max(8, Math.min(popup.width - width - 8, popup.anchorX - width / 2))
                        implicitWidth: Math.max(180, Math.min(340, col.implicitWidth + 12))
                        implicitHeight: col.implicitHeight + 12
                        radius: 12
                        color: Qt.rgba(Colors.surfaceContainer.r, Colors.surfaceContainer.g,
                                       Colors.surfaceContainer.b, 0.97)
                        border.width: 1
                        border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.35)

                        // Клик по самой карточке (поля, разделители) меню не закрывает
                        MouseArea { anchors.fill: parent }

                        ColumnLayout {
                            id: col
                            x: 6
                            y: 6
                            width: card.width - 12
                            spacing: 2

                            // Назад из подменю
                            Rectangle {
                                visible: popup.stack.length > 0
                                Layout.fillWidth: true
                                implicitHeight: 28
                                radius: 8
                                color: backMouse.containsMouse ? Colors.surfaceContainerHighest : "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8
                                    Text {
                                        text: ""
                                        color: Colors.text
                                        font.family: "Symbols Nerd Font"
                                        font.pixelSize: 11
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: "Назад"
                                        color: Colors.text
                                        font.family: Settings.uiFontFamily
                                        font.pixelSize: 13
                                    }
                                }
                                MouseArea {
                                    id: backMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: popup.stack = popup.stack.slice(0, -1)
                                }
                            }

                            Repeater {
                                model: opener.children

                                Rectangle {
                                    id: entry
                                    required property var modelData
                                    readonly property bool sep: modelData.isSeparator

                                    Layout.fillWidth: true
                                    implicitWidth: sep ? 0 : entryRow.implicitWidth + 20
                                    implicitHeight: sep ? 9 : 28
                                    radius: 8
                                    color: !sep && modelData.enabled && entryMouse.containsMouse
                                           ? Colors.surfaceContainerHighest : "transparent"

                                    // Разделитель
                                    Rectangle {
                                        visible: entry.sep
                                        anchors.centerIn: parent
                                        width: parent.width - 16
                                        height: 1
                                        color: Colors.text
                                        opacity: 0.15
                                    }

                                    RowLayout {
                                        id: entryRow
                                        visible: !entry.sep
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 8
                                        opacity: entry.modelData.enabled ? 1 : 0.4

                                        // Галочка у переключаемых пунктов
                                        Text {
                                            visible: entry.modelData.buttonType !== QsMenuButtonType.None
                                            text: entry.modelData.checkState === Qt.Checked ? "" : ""
                                            color: Colors.primary
                                            font.family: "Symbols Nerd Font"
                                            font.pixelSize: 11
                                            Layout.preferredWidth: 12
                                        }

                                        IconImage {
                                            visible: entry.modelData.icon !== ""
                                            source: entry.modelData.icon
                                            implicitSize: 16
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: entry.modelData.text
                                            elide: Text.ElideRight
                                            color: Colors.text
                                            font.family: Settings.uiFontFamily
                                            font.pixelSize: 13
                                        }

                                        // Стрелка у пунктов с подменю
                                        Text {
                                            visible: entry.modelData.hasChildren
                                            text: ""
                                            color: Colors.text
                                            font.family: "Symbols Nerd Font"
                                            font.pixelSize: 11
                                        }
                                    }

                                    MouseArea {
                                        id: entryMouse
                                        anchors.fill: parent
                                        enabled: !entry.sep && entry.modelData.enabled
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (entry.modelData.hasChildren) {
                                                popup.stack = popup.stack.concat([entry.modelData])
                                            } else {
                                                entry.modelData.triggered()
                                                pill.openItem = null
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
