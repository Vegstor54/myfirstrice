import QtQuick
import QtQuick.Layouts
import ".."
import "DisplaysLogic.js" as Logic

// Строка монитора на странице «Дисплеи»: шапка с названием и переключателем,
// по клику раскрывается: разрешение, частота, масштаб, поворот, «основной при старте».
Rectangle {
    id: row

    property var mon: ({ modes: [] })
    property bool expanded: false
    property bool isPrimary: false

    signal headerClicked()
    signal enabledToggled(bool on)
    signal resolutionPicked(int w, int h)
    signal refreshPicked(real hz)
    signal scalePicked(real scale)
    signal transformPicked(int transform)
    signal primaryRequested()

    readonly property var resList: Logic.resolutions(mon.modes ?? [])
    readonly property var hzList: Logic.refreshes(mon.modes ?? [], mon.w, mon.h)

    implicitHeight: body.implicitHeight + 24
    radius: Settings.r(16)
    color: Settings.fill
    border.width: 0

    ColumnLayout {
        id: body
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 10

        Item {
            Layout.fillWidth: true
            implicitHeight: headRow.implicitHeight

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: row.headerClicked()
            }

            RowLayout {
                id: headRow
                anchors.fill: parent
                spacing: 10

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        spacing: 8

                        Text {
                            text: row.mon.name ?? ""
                            color: Colors.text
                            font.family: Settings.uiFontFamily
                            font.pixelSize: 15
                            font.bold: true
                        }
                        Rectangle {
                            visible: row.isPrimary && row.mon.enabled
                            implicitWidth: primaryLabel.implicitWidth + 14
                            implicitHeight: 18
                            radius: Settings.r(999)
                            color: Colors.primary

                            Text {
                                id: primaryLabel
                                anchors.centerIn: parent
                                text: "основной"
                                color: Colors.textOnPrimary
                                font.family: Settings.uiFontFamily
                                font.pixelSize: 11
                            }
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: row.mon.desc ?? ""
                        elide: Text.ElideRight
                        color: Colors.text
                        opacity: 0.6
                        font.family: Settings.uiFontFamily
                        font.pixelSize: 11
                    }
                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        // Как в макете: «1920×1200@59.95 · масштаб 0.75», у зеркала — его источник
                        text: row.mon.enabled
                            ? row.mon.w + "×" + row.mon.h + "@" + Logic.fmtHz(row.mon.hz)
                                + " · масштаб " + Logic.fmtScale(row.mon.scale)
                                + ((row.mon.mirror ?? "") !== "" ? " · зеркало " + row.mon.mirror : "")
                            : "Выключен"
                        color: Colors.text
                        opacity: 0.8
                        font.family: Settings.uiFontFamily
                        font.pixelSize: 12
                    }
                }

                // Быстрый выбор разрешения прямо в шапке строки; список раскрывается под ним
                OptionPicker {
                    visible: row.mon.enabled === true
                    Layout.preferredWidth: 150
                    Layout.alignment: Qt.AlignTop
                    options: row.resList.map(r => r.w + " × " + r.h)
                    current: row.mon.w + " × " + row.mon.h
                    onPicked: index => row.resolutionPicked(row.resList[index].w, row.resList[index].h)
                }

                Text {
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: 8
                    text: row.mon.enabled ? "Вкл" : "Выкл"
                    color: Colors.text
                    opacity: 0.8
                    font.family: Settings.uiFontFamily
                    font.pixelSize: 13
                }

                // Переключатель «включён / выключен»
                Rectangle {
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: 5
                    Layout.preferredWidth: 42
                    Layout.preferredHeight: 24
                    radius: Settings.r(999)
                    color: row.mon.enabled ? Colors.primary : Settings.fillActive
                    border.width: 0

                    Rectangle {
                        width: 18
                        height: 18
                        radius: Settings.r(999)
                        anchors.verticalCenter: parent.verticalCenter
                        x: row.mon.enabled ? parent.width - width - 3 : 3
                        color: row.mon.enabled ? Colors.textOnPrimary : Colors.text
                        Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: row.enabledToggled(!row.mon.enabled)
                    }
                }

                // Стрелка раскрытия настроек строки
                Text {
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: 8
                    text: row.expanded ? "▴" : "▾"
                    color: Colors.text
                    opacity: 0.7
                    font.family: Settings.uiFontFamily
                    font.pixelSize: 13
                }
            }
        }

        ColumnLayout {
            visible: row.expanded && row.mon.enabled === true
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "Частота обновления"
                color: Colors.text
                opacity: 0.7
                font.family: Settings.uiFontFamily
                font.pixelSize: 12
            }
            OptionPicker {
                Layout.fillWidth: true
                options: row.hzList.map(h => Logic.fmtHz(h) + " Гц")
                current: Logic.fmtHz(row.mon.hz) + " Гц"
                onPicked: index => row.refreshPicked(row.hzList[index])
            }

            Text {
                text: "Масштаб"
                color: Colors.text
                opacity: 0.7
                font.family: Settings.uiFontFamily
                font.pixelSize: 12
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: [0.75, 1, 1.25, 1.5, 2]

                    BarChip {
                        required property real modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        idleColor: Settings.fillHover
                        hoverColor: Settings.fillActive
                        label: Math.round(modelData * 100) + "%"
                        selected: Math.abs(row.mon.scale - modelData) < 0.01
                        onClicked: row.scalePicked(modelData)
                    }
                }
            }

            Text {
                text: "Поворот"
                color: Colors.text
                opacity: 0.7
                font.family: Settings.uiFontFamily
                font.pixelSize: 12
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: [0, 1, 2, 3]

                    BarChip {
                        required property int modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        idleColor: Settings.fillHover
                        hoverColor: Settings.fillActive
                        label: (modelData * 90) + "°"
                        selected: row.mon.transform === modelData
                        onClicked: row.transformPicked(modelData)
                    }
                }
            }

            BarChip {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                idleColor: Settings.fillHover
                hoverColor: Settings.fillActive
                label: "Основной при старте"
                selected: row.isPrimary
                onClicked: row.primaryRequested()
            }
        }
    }
}
