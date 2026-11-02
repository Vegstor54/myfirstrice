import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import ".."

// Большая версия показателей CPU и памяти: выезжает из-под бара по клику на кольцо (или значение) в баре.
// Слева крупное кольцо-«спидометр», справа подробности; для CPU внизу столбики по ядрам.
// Устройство окна то же, что у ClockMenu: закрывается кликом вне меню или Esc.
Scope {
    id: root

    property bool shown: false
    property string kind: "cpu"       // "cpu" или "ram"
    property string monitor: ""
    property real anchorX: 100000

    function toggle(statKind, monitorName, centerX) {
        if (shown && monitor === monitorName && kind === statKind) {
            shown = false
            return
        }
        kind = statKind
        monitor = monitorName
        if (centerX !== undefined) anchorX = centerX
        shown = true
    }

    // Для проверки и бинда: quickshell ipc call stats toggle cpu|ram (на сфокусированном мониторе)
    IpcHandler {
        target: "stats"
        function toggle(statKind: string): void {
            root.toggle(statKind === "ram" ? "ram" : "cpu",
                        Hyprland.focusedMonitor?.name ?? Quickshell.screens[0]?.name ?? "")
        }
    }

    readonly property bool isRam: kind === "ram"
    readonly property real percent: isRam ? SysStats.ramPct : SysStats.cpu

    function gib(v) { return v.toFixed(1) + " ГиБ" }

    // Строки справа от кольца: [название, значение]
    readonly property var rows: isRam
        ? [["Занято", gib(SysStats.ramGb) + " из " + gib(SysStats.ramTotalGb)],
           ["Доступно", gib(SysStats.ramFreeGb)],
           ["Кэш", gib(SysStats.ramCachedGb)],
           ["Своп", SysStats.swapTotalGb > 0 ? gib(SysStats.swapUsedGb) + " из " + gib(SysStats.swapTotalGb) : "нет"]]
        : [["Нагрузка 1 / 5 / 15 мин", SysStats.load.map(x => x.toFixed(2)).join("  ·  ")],
           ["Ядер", String(SysStats.cores.length)]]

    // Курсор ушёл на другой монитор: закрываем меню
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

            // Прозрачный фон на весь экран, в том числе поверх бара: клик вне меню закрывает его
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
                visible: win.isTarget
                property real slide: root.shown ? 0 : -16

                anchors.top: parent.top
                anchors.topMargin: Settings.barHeight + Settings.barTop + 8 + slide
                x: Math.max(Settings.barSideMargin,
                            Math.min(parent.width - width - Settings.barSideMargin, root.anchorX - width / 2))
                width: 440
                height: content.implicitHeight + 40
                radius: Settings.r(24)
                color: Qt.rgba(Colors.surfaceContainer.r, Colors.surfaceContainer.g, Colors.surfaceContainer.b, 0.95)
                border.width: 1
                border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.35)
                opacity: root.shown ? 1 : 0

                Behavior on opacity { NumberAnimation { id: fade; duration: 180; easing.type: Easing.OutCubic } }
                Behavior on slide { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                // Клики по самой карточке не закрывают меню
                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    id: content
                    x: 20
                    y: 20
                    width: card.width - 40
                    spacing: 18

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 20

                        GaugeRing {
                            size: 150
                            lineWidth: 14
                            percent: root.percent
                            numberScale: 0.34
                            Layout.preferredWidth: 150
                            Layout.preferredHeight: 150
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Text {
                                text: root.isRam ? "Память" : "Процессор"
                                color: Colors.text
                                font.family: Settings.uiFontFamily
                                font.pixelSize: 20
                                font.bold: true
                            }

                            Repeater {
                                model: root.rows.length

                                ColumnLayout {
                                    id: infoRow
                                    required property int index
                                    Layout.fillWidth: true
                                    spacing: 0

                                    Text {
                                        text: root.rows[infoRow.index][0]
                                        color: Colors.text
                                        opacity: 0.65
                                        font.family: Settings.uiFontFamily
                                        font.pixelSize: 12
                                    }
                                    Text {
                                        text: root.rows[infoRow.index][1]
                                        color: Colors.text
                                        font.family: Settings.uiFontFamily
                                        font.pixelSize: 15
                                    }
                                }
                            }
                        }
                    }

                    // Столбики по ядрам: только для процессора
                    RowLayout {
                        visible: !root.isRam && SysStats.cores.length > 0
                        Layout.fillWidth: true
                        Layout.preferredHeight: 64
                        spacing: 4

                        Repeater {
                            model: SysStats.cores.length

                            Rectangle {
                                id: coreBar
                                required property int index
                                readonly property real pct: SysStats.cores[index] ?? 0

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: Settings.r(4)
                                color: Qt.alpha(Colors.text, 0.12)

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: Math.max(2, parent.height * coreBar.pct / 100)
                                    radius: parent.radius
                                    color: coreBar.pct >= 85 ? Colors.error : Colors.primary
                                    Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                                }
                            }
                        }
                    }

                    Text {
                        visible: !root.isRam && SysStats.cores.length > 0
                        text: "Загрузка по ядрам"
                        color: Colors.text
                        opacity: 0.65
                        font.family: Settings.uiFontFamily
                        font.pixelSize: 12
                    }
                }
            }
        }
    }
}
