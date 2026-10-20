import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts

// Вкладка Bluetooth в выезжающем меню: включение адаптера и два списка.
//  - «Сопряжённые»: клик подключает или отключает устройство, «Забыть» удаляет его
//  - «Найти новые»: идёт поиск устройств рядом, клик сопрягает (через scripts/bt-pair.sh)
// Поиск работает только пока открыт список «Найти новые» и выключается при выходе из него.
// Загружается из QuickMenu через Loader (в qmldir не регистрируется), чтобы отсутствие
// модуля Quickshell.Bluetooth не ломало остальную оболочку.
ColumnLayout {
    id: tab
    spacing: 12

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property string scripts: Quickshell.env("HOME") + "/.config/quickshell/scripts"

    // "paired" — сопряжённые, "scan" — поиск и сопряжение новых
    property string view: "paired"
    property string message: ""
    // Адрес устройства, которое сопрягается сейчас (пусто — ничего не идёт)
    property string pairingAddress: ""

    function deviceName(d) { return d.name || d.deviceName || d.address }

    // Безымянные устройства BlueZ называет по адресу (90-F2-60-...): в поиске их не показываем
    function hasRealName(d) {
        const n = d.deviceName || d.name || ""
        return n !== "" && !/^([0-9A-F]{2}[-:]){5}[0-9A-F]{2}$/i.test(n)
    }

    function batteryText(d) {
        return d.batteryAvailable ? " · " + Math.round(d.battery * 100) + "%" : ""
    }

    // Сопряжённые: подключённые сверху
    readonly property var pairedDevices: Bluetooth.devices.values
        .filter(d => d.paired || d.connected)
        .sort((a, b) => (a.connected ? 0 : 1) - (b.connected ? 0 : 1)
                        || deviceName(a).localeCompare(deviceName(b)))

    // Найденные рядом и ещё не сопряжённые
    readonly property var foundDevices: Bluetooth.devices.values
        .filter(d => !d.paired && !d.connected && hasRealName(d))
        .sort((a, b) => deviceName(a).localeCompare(deviceName(b)))

    // ---- Поиск устройств ----
    // Включаем и выключаем только если состояние отличается: BlueZ отвечает ошибкой
    // на повторный запуск и на остановку несуществующего поиска
    function startDiscovery() {
        if (view === "scan" && adapter && adapter.enabled && !adapter.discovering)
            adapter.discovering = true
    }

    function stopDiscovery() {
        if (adapter && adapter.discovering) adapter.discovering = false
    }

    onViewChanged: {
        attempts = 0
        message = ""
        if (view === "scan") startDiscovery()
        else stopDiscovery()
    }

    // Сразу после запуска BlueZ может ответить «Resource Not Ready». Пробуем ещё несколько раз
    // с паузой, пока поиск не стартует; счётчик сбрасывается, когда поиск пошёл
    property int attempts: 0

    Timer {
        interval: 1500
        repeat: true
        running: tab.view === "scan" && !!tab.adapter && tab.adapter.enabled
                 && !tab.adapter.discovering && tab.attempts < 5
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
        function onEnabledChanged() { tab.startDiscovery() }
    }

    Component.onDestruction: stopDiscovery()

    // ---- Сопряжение новых устройств ----
    Process {
        id: pairProc
        command: [tab.scripts + "/bt-pair.sh", tab.pairingAddress]
        onExited: code => {
            tab.pairingAddress = ""
            if (code === 0) tab.view = "paired"
            else if (code === 2) tab.message = "Не найден bluetoothctl: установи пакет bluez-utils"
            else tab.message = "Не удалось сопрячь. Переведи устройство в режим сопряжения и попробуй снова"
        }
    }

    function pair(d) {
        if (pairingAddress !== "") return
        message = ""
        pairingAddress = d.address
        pairProc.running = true
    }

    // ---- Интерфейс ----

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

    // Переключатель списков
    RowLayout {
        Layout.fillWidth: true
        visible: !!tab.adapter && tab.adapter.enabled
        spacing: 8

        Repeater {
            model: [
                { id: "paired", label: "Сопряжённые" },
                { id: "scan",   label: "Найти новые" }
            ]

            Rectangle {
                id: viewChip
                required property var modelData
                readonly property bool selected: tab.view === modelData.id

                Layout.fillWidth: true
                Layout.preferredHeight: 32
                radius: 999
                color: selected ? Colors.primary
                     : viewMouse.containsMouse ? Colors.surfaceContainerHighest
                     : Colors.surfaceContainerHigh

                Text {
                    anchors.centerIn: parent
                    text: viewChip.modelData.label
                    color: viewChip.selected ? Colors.textOnPrimary : Colors.text
                    font.family: Settings.uiFontFamily
                    font.pixelSize: 13
                }
                MouseArea {
                    id: viewMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: tab.view = viewChip.modelData.id
                }
            }
        }
    }

    // Список «Сопряжённые»
    ListView {
        id: pairedList
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: !!tab.adapter && tab.adapter.enabled && tab.view === "paired"
        clip: true
        spacing: 6
        model: tab.pairedDevices

        delegate: BluetoothDeviceRow {
            id: pairedRow
            required property var modelData

            width: pairedList.width
            title: tab.deviceName(modelData)
            subtitle: modelData.connected ? "Подключено" + tab.batteryText(modelData)
                                          : "Сопряжено · нажми, чтобы подключить"
            highlighted: modelData.connected
            actionLabel: "Забыть"

            onClicked: {
                if (modelData.connected) {
                    modelData.connected = false
                } else {
                    // Доверенное устройство BlueZ не разрывает сразу после подключения
                    modelData.trusted = true
                    modelData.connected = true
                }
            }
            onActionClicked: modelData.forget()
        }
    }

    // Список «Найти новые»
    ListView {
        id: foundList
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: !!tab.adapter && tab.adapter.enabled && tab.view === "scan"
        clip: true
        spacing: 6
        model: tab.foundDevices

        delegate: BluetoothDeviceRow {
            id: foundRow
            required property var modelData

            width: foundList.width
            title: tab.deviceName(modelData)
            subtitle: tab.pairingAddress === modelData.address ? "Сопряжение…"
                                                                : "Нажми, чтобы сопрячь"
            highlighted: tab.pairingAddress === modelData.address

            onClicked: tab.pair(modelData)
        }
    }

    // Подсказки, когда список пуст
    Text {
        Layout.alignment: Qt.AlignHCenter
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        visible: !!tab.adapter && tab.adapter.enabled
                 && ((tab.view === "paired" && tab.pairedDevices.length === 0)
                     || (tab.view === "scan" && tab.foundDevices.length === 0))
        text: tab.view === "paired" ? "Сопряжённых устройств нет. Открой «Найти новые»"
                                    : "Пока ничего нет. Переведи устройство в режим сопряжения"
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

    // Сообщение об ошибке
    Text {
        Layout.fillWidth: true
        visible: tab.message !== ""
        text: tab.message
        color: Colors.error
        wrapMode: Text.WordWrap
        font.family: Settings.uiFontFamily
        font.pixelSize: 12
    }
}
