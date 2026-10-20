import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts

// Вкладка Bluetooth в выезжающем меню: включение адаптера и список устройств.
// Клик по устройству: сопряжённое подключается или отключается, новое сопрягается.
// Пока вкладка открыта, идёт поиск устройств рядом; при закрытии он выключается.
// Загружается из QuickMenu через Loader (в qmldir не регистрируется), чтобы отсутствие
// модуля Quickshell.Bluetooth не ломало остальную оболочку.
ColumnLayout {
    id: tab
    spacing: 12

    readonly property var adapter: Bluetooth.defaultAdapter

    function deviceName(d) { return d.name || d.deviceName || d.address }

    // Подключённые сверху, затем сопряжённые, затем найденные рядом
    readonly property var devices: {
        const rank = d => d.connected ? 0 : d.paired ? 1 : 2
        return Bluetooth.devices.values
            .filter(d => d.paired || d.connected || d.deviceName !== "")
            .sort((a, b) => rank(a) - rank(b) || deviceName(a).localeCompare(deviceName(b)))
    }

    // Поиск включаем и выключаем только если состояние отличается: BlueZ отвечает
    // ошибкой на повторный запуск и на остановку несуществующего поиска
    function startDiscovery() {
        if (adapter && adapter.enabled && !adapter.discovering) adapter.discovering = true
    }

    // Сразу после запуска BlueZ может ответить «Resource Not Ready». Пробуем ещё несколько раз
    // с паузой, пока поиск не стартует; счётчик сбрасывается, когда поиск пошёл
    property int attempts: 0

    Timer {
        interval: 1500
        repeat: true
        running: !!tab.adapter && tab.adapter.enabled && !tab.adapter.discovering && tab.attempts < 5
        onTriggered: {
            tab.attempts++
            tab.startDiscovery()
        }
    }

    Connections {
        target: tab.adapter
        function onDiscoveringChanged() {
            if (tab.adapter.discovering) tab.attempts = 0
        }
    }

    Component.onCompleted: startDiscovery()

    Component.onDestruction: {
        if (adapter && adapter.discovering) adapter.discovering = false
    }

    // Включили адаптер: сразу начинаем поиск
    Connections {
        target: tab.adapter
        function onEnabledChanged() { tab.startDiscovery() }
    }

    // Адаптера нет: нет железа или не запущен сервис bluetooth
    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: !tab.adapter
        spacing: 4

        Item { Layout.fillHeight: true }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Bluetooth не найден"
            color: Colors.text
            font.family: Settings.uiFontFamily
            font.pixelSize: 15
            font.bold: true
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Проверь, что запущен сервис bluetooth"
            color: Colors.text
            opacity: 0.6
            font.family: Settings.uiFontFamily
            font.pixelSize: 12
        }
        Item { Layout.fillHeight: true }
    }

    // Заголовок: состояние адаптера и переключатель
    RowLayout {
        Layout.fillWidth: true
        visible: !!tab.adapter

        ColumnLayout {
            spacing: 2

            Text {
                text: "Bluetooth"
                color: Colors.text
                font.family: Settings.uiFontFamily
                font.pixelSize: 14
                font.bold: true
            }
            Text {
                text: !tab.adapter ? ""
                    : !tab.adapter.enabled ? "Выключен"
                    : tab.adapter.discovering ? "Поиск устройств…"
                    : "Включён"
                color: Colors.text
                opacity: 0.6
                font.family: Settings.uiFontFamily
                font.pixelSize: 12
            }
        }

        Item { Layout.fillWidth: true }

        Rectangle {
            Layout.preferredWidth: 104
            Layout.preferredHeight: 32
            radius: 999
            color: tab.adapter && tab.adapter.enabled ? Colors.primary
                 : powerMouse.containsMouse ? Colors.surfaceContainerHighest
                 : Colors.surfaceContainerHigh

            Text {
                anchors.centerIn: parent
                text: tab.adapter && tab.adapter.enabled ? "Включён" : "Выключен"
                color: tab.adapter && tab.adapter.enabled ? Colors.textOnPrimary : Colors.text
                font.family: Settings.uiFontFamily
                font.pixelSize: 13
            }
            MouseArea {
                id: powerMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: tab.adapter.enabled = !tab.adapter.enabled
            }
        }
    }

    // Список устройств
    ListView {
        id: list
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: !!tab.adapter && tab.adapter.enabled
        clip: true
        spacing: 6
        model: tab.devices

        delegate: Rectangle {
            id: item
            required property var modelData
            // Идёт сопряжение, нажатое из этого списка
            property bool pairing: false

            width: list.width
            height: 44
            radius: 14
            color: modelData.connected ? Colors.primaryContainer
                 : itemMouse.containsMouse ? Colors.surfaceContainerHighest
                 : Colors.surfaceContainerHigh

            ColumnLayout {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: tab.deviceName(item.modelData)
                    elide: Text.ElideRight
                    color: Colors.text
                    font.family: Settings.uiFontFamily
                    font.pixelSize: 13
                    font.bold: item.modelData.connected
                }
                Text {
                    Layout.fillWidth: true
                    text: (item.modelData.connected ? "Подключено"
                         : item.modelData.paired ? "Сопряжено"
                         : "Нажми, чтобы сопрячь")
                        + (item.modelData.connected && item.modelData.batteryAvailable
                            ? " · " + Math.round(item.modelData.battery * 100) + "%" : "")
                    elide: Text.ElideRight
                    color: Colors.text
                    opacity: 0.6
                    font.family: Settings.uiFontFamily
                    font.pixelSize: 11
                }
            }

            // После успешного сопряжения сразу подключаемся
            Connections {
                target: item.modelData
                function onPairedChanged() {
                    if (item.pairing && item.modelData.paired) {
                        item.pairing = false
                        item.modelData.connected = true
                    }
                }
            }

            MouseArea {
                id: itemMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (!item.modelData.paired) {
                        // Доверенное устройство BlueZ не разрывает сразу после сопряжения
                        item.pairing = true
                        item.modelData.trusted = true
                        item.modelData.pair()
                    } else {
                        item.modelData.connected = !item.modelData.connected
                    }
                }
            }
        }
    }

    // Список пуст
    Text {
        Layout.alignment: Qt.AlignHCenter
        visible: !!tab.adapter && tab.adapter.enabled && tab.devices.length === 0
        text: "Устройств пока не найдено"
        color: Colors.text
        opacity: 0.6
        font.family: Settings.uiFontFamily
        font.pixelSize: 12
    }

    // Адаптер выключен
    Text {
        Layout.alignment: Qt.AlignHCenter
        visible: !!tab.adapter && !tab.adapter.enabled
        text: "Включи Bluetooth, чтобы увидеть устройства"
        color: Colors.text
        opacity: 0.6
        font.family: Settings.uiFontFamily
        font.pixelSize: 12
    }
}
