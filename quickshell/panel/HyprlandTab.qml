import Quickshell
import QtQuick
import QtQuick.Layouts
import ".."

Flickable {
    id: tab

    signal closeRequested()

    clip: true
    contentWidth: width
    contentHeight: content.implicitHeight
    boundsBehavior: Flickable.StopAtBounds

    readonly property string scripts: Quickshell.env("HOME") + "/.config/quickshell/scripts"

    function openConfig(path) {
        Quickshell.execDetached([scripts + "/open-hypr-config.sh", path])
        closeRequested()
    }

    ColumnLayout {
        id: content
        width: tab.width
        spacing: 16

        Text {
            Layout.fillWidth: true
            text: "Выберите файл, чтобы открыть его в редакторе из Defaults."
            wrapMode: Text.WordWrap
            color: Colors.text
            opacity: 0.7
            font.family: Settings.uiFontFamily
            font.pixelSize: 13
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 8
            rowSpacing: 8

            Repeater {
                model: [
                    { label: "Главный файл",  path: "hyprland.lua",        icon: "󰌌" },
                    { label: "Мониторы",      path: "conf/monitors.lua",  icon: "󰍹" },
                    { label: "Программы",     path: "conf/programs.lua",  icon: "󰆍" },
                    { label: "Автозапуск",    path: "conf/autostart.lua", icon: "󰜉" },
                    { label: "Внешний вид",   path: "conf/look.lua",      icon: "󰃣" },
                    { label: "Анимации",      path: "conf/animations.lua", icon: "󰔛" },
                    { label: "Раскладки",     path: "conf/layouts.lua",   icon: "󰕰" },
                    { label: "Ввод",          path: "conf/input.lua",     icon: "󰌌" },
                    { label: "Горячие клавиши", path: "conf/binds.lua",   icon: "󰘳" },
                    { label: "Правила окон",  path: "conf/rules.lua",     icon: "󰖯" },
                    { label: "Переменные",    path: "conf/env.lua",       icon: "󰘵" }
                ]

                Rectangle {
                    id: button
                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 64
                    radius: Settings.r(16)
                    color: mouse.containsMouse ? Settings.fillHover : Settings.fill
                    border.width: 0

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 10
                        spacing: 10

                        Text {
                            text: button.modelData.icon
                            color: Colors.primary
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 20
                        }

                        Text {
                            Layout.fillWidth: true
                            text: button.modelData.label
                            elide: Text.ElideRight
                            color: Colors.text
                            font.family: Settings.uiFontFamily
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }

                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: tab.openConfig(button.modelData.path)
                    }
                }
            }
        }

        Item { Layout.preferredHeight: 1 }
    }
}
