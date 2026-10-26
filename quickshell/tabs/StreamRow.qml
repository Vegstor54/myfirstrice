import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import ".."

// Приложение, которое сейчас играет: громкость и выбор устройства вывода.
// Нажатие на устройство переносит звук этого приложения на него (scripts/move-stream.sh).
ColumnLayout {
    id: stream

    // Узел PipeWire потока приложения
    required property var node

    spacing: 6

    // К какому устройству вывода сейчас подключён поток
    PwNodeLinkTracker { id: tracker; node: stream.node }

    readonly property var target: {
        const groups = tracker.linkGroups
        for (let i = 0; i < groups.length; i++) {
            if (groups[i].source && groups[i].source.id === stream.node.id)
                return groups[i].target
        }
        return null
    }

    MixerRow {
        Layout.fillWidth: true
        title: SysState.appName(stream.node)
        value: stream.node.audio?.volume ?? 0
        muted: stream.node.audio?.muted ?? false
        onSetValue: v => SysState.setNodeVolume(stream.node, v)
        onStep: d => SysState.setNodeVolume(stream.node, (stream.node.audio?.volume ?? 0) + d)
        onToggleMute: SysState.toggleNodeMute(stream.node)
    }

    // Куда играет: нажатие на устройство переносит поток на него
    Flow {
        Layout.fillWidth: true
        spacing: 6

        Repeater {
            model: SysState.sinks

            Rectangle {
                id: chip
                required property var modelData
                readonly property bool selected: !!stream.target && stream.target.id === modelData.id

                width: Math.min(chipText.implicitWidth + 20, 180)
                height: 24
                radius: Settings.r(12)
                color: selected ? Colors.primary
                     : chipMouse.containsMouse ? Settings.fillHover
                     : Settings.fill
                border.width: 0

                Text {
                    id: chipText
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    text: SysState.sinkName(chip.modelData)
                    elide: Text.ElideRight
                    color: chip.selected ? Colors.textOnPrimary : Colors.text
                    font.family: Settings.uiFontFamily
                    font.pixelSize: 11
                }
                MouseArea {
                    id: chipMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: SysState.moveStream(stream.node, chip.modelData)
                }
            }
        }
    }
}
