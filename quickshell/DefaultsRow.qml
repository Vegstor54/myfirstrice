import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: row
    required property string label
    required property string category
    property var installed: []
    property string current: ""
    spacing: 6

    readonly property string scripts: Quickshell.env("HOME") + "/.config/quickshell/scripts"

    Process {
        command: [row.scripts + "/check-installed.sh", row.category]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try { row.installed = JSON.parse(text) }
                catch (e) { console.log("parse error:", e) }
            }
        }
    }

    Process {
        id: reader
        command: [row.scripts + "/get-default.sh", row.category]
        running: true
        stdout: StdioCollector {
            onStreamFinished: row.current = text.trim()
        }
    }

    Process {
        id: setter
        property string app: ""
        command: [row.scripts + "/set-default.sh", row.category, app]
        onExited: reader.running = true
    }

    Text { text: row.label; color: Colors.text; font.family: Settings.uiFontFamily; font.pixelSize: 14; font.bold: true }

    Flow {
        Layout.fillWidth: true
        Layout.preferredHeight: childrenRect.height
        spacing: 8

        Repeater {
            model: row.installed

            Rectangle {
                required property string modelData
                width: 110; height: 32; radius: 999
                color: modelData === row.current ? Colors.primary
                     : mouse.containsMouse ? Colors.surfaceContainerHighest
                     : Colors.surfaceContainerHigh

                Text {
                    anchors.centerIn: parent
                    text: parent.modelData
                    color: parent.modelData === row.current ? Colors.textOnPrimary : Colors.text
                    font.family: Settings.uiFontFamily
                    font.pixelSize: 12
                }
                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        console.log("set default:", row.category, parent.modelData)
                        setter.app = parent.modelData
                        setter.running = true
                    }
                }
            }
        }
    }
}
