import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Вкладка «Звук» в выезжающем меню: микшер.
//   Устройства вывода — громкость и выключение звука у каждого, нажатие на название делает устройство основным.
//   Приложения — громкость каждого играющего приложения и выбор, на какое устройство оно играет.
//   Микрофон — громкость и выключение (устройство по умолчанию).
Flickable {
    id: flick
    clip: true
    contentWidth: width
    contentHeight: col.implicitHeight
    boundsBehavior: Flickable.StopAtBounds

    ScrollBar.vertical: ScrollBar {
        id: bar
        policy: ScrollBar.AsNeeded
        implicitWidth: 6
        background: Item {}
        contentItem: Rectangle {
            implicitWidth: 6
            radius: 3
            color: Colors.primary
            opacity: bar.pressed ? 0.9 : bar.active ? 0.6 : 0.3
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
    }

    ColumnLayout {
        id: col
        // Справа остаётся место под полосу прокрутки
        width: flick.width - 12
        spacing: 12

        Text {
            text: "Устройства вывода"
            color: Colors.text
            font.family: Settings.uiFontFamily
            font.pixelSize: 14
            font.bold: true
        }

        Repeater {
            model: SysState.sinks

            MixerRow {
                id: sinkRow
                required property var modelData
                readonly property bool isDefault: !!SysState.sink && modelData.id === SysState.sink.id

                Layout.fillWidth: true
                title: SysState.sinkName(modelData)
                highlighted: isDefault
                badge: isDefault ? "по умолчанию" : ""
                titleClickable: !isDefault
                value: modelData.audio?.volume ?? 0
                muted: modelData.audio?.muted ?? false
                onTitleClicked: SysState.setDefaultSink(modelData)
                onSetValue: v => SysState.setNodeVolume(modelData, v)
                onStep: d => SysState.setNodeVolume(modelData, (modelData.audio?.volume ?? 0) + d)
                onToggleMute: SysState.toggleNodeMute(modelData)
            }
        }

        Text {
            visible: SysState.sinks.length === 0
            text: "Устройства вывода не найдены"
            color: Colors.text
            opacity: 0.6
            font.family: Settings.uiFontFamily
            font.pixelSize: 12
        }

        Text {
            text: "Приложения"
            color: Colors.text
            font.family: Settings.uiFontFamily
            font.pixelSize: 14
            font.bold: true
        }

        Repeater {
            model: SysState.streams

            StreamRow {
                required property var modelData
                Layout.fillWidth: true
                node: modelData
            }
        }

        Text {
            visible: SysState.streams.length === 0
            text: "Сейчас ничего не играет"
            color: Colors.text
            opacity: 0.6
            font.family: Settings.uiFontFamily
            font.pixelSize: 12
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
    }
}
