import Quickshell
import Quickshell.Hyprland
import QtQuick

// Рабочие столы в баре: квадраты с номерами.
//  - активный на этом мониторе: цвет primary
//  - с окнами: светлая плашка
//  - пустые (только в режимах 1–5 и 1–10): тёмные, приглушённые
//  - в режимах 1–5 и 1–10 столы сверх диапазона появляются, только когда заняты окнами
// Режим берётся из Settings.wsMode: "used" | "5" | "10".
// Клик по квадрату переключает на этот рабочий стол.
Row {
    id: root

    // id активного рабочего стола на мониторе этого бара (передаёт shell.qml)
    property int activeId: -1

    spacing: 4

    // Какие номера показывать
    readonly property var ids: {
        const mode = Settings.wsMode
        if (mode === "5" || mode === "10") {
            const n = parseInt(mode)
            const list = []
            for (let i = 1; i <= n; i++) list.push(i)
            // За пределами диапазона показываем только занятые окнами столы
            // и активный; пустые номера больше n не появляются
            const extra = Hyprland.workspaces.values
                .filter(w => w.id > n && (w.id === activeId || w.toplevels.values.length > 0))
                .map(w => w.id)
            if (activeId > n && extra.indexOf(activeId) === -1) extra.push(activeId)
            extra.sort((a, b) => a - b)
            return list.concat(extra)
        }
        // "used": существующие рабочие столы (с окнами и активные), без special
        return Hyprland.workspaces.values
            .filter(w => w.id > 0)
            .map(w => w.id)
            .sort((a, b) => a - b)
    }

    Repeater {
        model: root.ids

        Rectangle {
            id: ws
            required property int modelData

            readonly property var hw: Hyprland.workspaces.values.find(w => w.id === modelData)
            readonly property bool active: modelData === root.activeId
            readonly property bool occupied: hw !== undefined && hw.toplevels.values.length > 0

            width: Settings.barHeight - 8
            height: width
            radius: Settings.barRounded ? 6 : 0
            color: active ? Colors.primary
                 : occupied ? Qt.rgba(1, 1, 1, 0.14)
                 : Qt.rgba(0, 0, 0, 0.18)

            Behavior on color { ColorAnimation { duration: 120 } }

            Text {
                anchors.centerIn: parent
                text: ws.modelData
                color: ws.active ? Colors.textOnPrimary : Colors.text
                opacity: ws.active || ws.occupied ? 1 : 0.4
                font.family: Settings.uiFontFamily
                font.pixelSize: Math.round(Settings.barHeight * 0.45)
                font.bold: ws.active
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                // Конфиг на Lua: диспетчер вызывается через hl.dsp (как в биндах hyprland.lua)
                onClicked: Quickshell.execDetached(["hyprctl", "dispatch",
                    "hl.dsp.focus({ workspace = " + ws.modelData + " })"])
            }
        }
    }
}
