import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import ".."

// Обои: миниатюра текущей картинки. Клик открывает выбор файла,
// можно и перетащить картинку на миниатюру.
// Дальше работает matugen/wallpaper-sync.sh: ставит обои, пересчитывает палитру, перезагружает Hyprland.
ColumnLayout {
    id: tab
    spacing: 16

    // Панель нужно закрыть до диалога: она лежит поверх всех окон и закрыла бы его
    signal closeRequested()

    readonly property string home: Quickshell.env("HOME")
    readonly property string scripts: home + "/.config/quickshell/scripts"
    readonly property string syncScript: home + "/.config/matugen/wallpaper-sync.sh"
    readonly property string current: cacheFile.text().trim()
    readonly property bool busy: picker.running || applier.running
    property string message: ""

    function isImage(path) { return /\.(png|jpe?g|webp|bmp|gif)$/i.test(path) }

    function apply(path) {
        if (!isImage(path)) {
            message = "Нужна картинка: png, jpg, webp, bmp или gif"
            return
        }
        message = ""
        applier.path = path
        applier.running = true
    }

    function pick() {
        message = ""
        closeRequested()
        picker.running = true
    }

    FileView {
        id: cacheFile
        path: tab.home + "/.cache/current-wallpaper"
        watchChanges: true
        onFileChanged: reload()
    }

    Process {
        id: picker
        command: [tab.scripts + "/pick-wallpaper.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                const path = text.trim()
                if (path !== "") tab.apply(path)
            }
        }
        onExited: code => {
            if (code === 2) tab.message = "Для выбора файла нужен zenity: sudo pacman -S zenity"
        }
    }

    Process {
        id: applier
        property string path: ""
        command: ["bash", tab.syncScript, path]
        onExited: code => {
            if (code !== 0) {
                tab.message = "Не удалось поставить обои"
                return
            }
            // matugen уже переписал Colors.qml, но Quickshell сам его не перечитывает:
            // перезагружаем оболочку, чтобы бар и панель взяли новую палитру
            Quickshell.reload(false)
        }
    }

    Text {
        text: "Обои"
        color: Colors.text
        font.family: Settings.uiFontFamily
        font.pixelSize: 14
        font.bold: true
    }

    // Миниатюра: она же кнопка выбора файла и зона для перетаскивания
    Item {
        id: preview
        Layout.fillWidth: true
        Layout.preferredHeight: 200

        Rectangle {
            id: frame
            anchors.fill: parent
            radius: Settings.r(16)
            color: Settings.fill
            border.width: 0
        }

        Image {
            id: image
            anchors.fill: parent
            visible: false
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: 720
            source: tab.current !== ""
                ? "file://" + tab.current.split("/").map(encodeURIComponent).join("/")
                : ""
        }

        Rectangle {
            id: mask
            anchors.fill: parent
            radius: Settings.r(16)
            visible: false
            layer.enabled: true
        }

        // Картинка со скруглёнными углами
        MultiEffect {
            anchors.fill: parent
            source: image
            maskEnabled: true
            maskSource: mask
            opacity: tab.busy ? 0.5 : 1
            visible: image.status === Image.Ready
        }

        Text {
            anchors.centerIn: parent
            visible: image.status !== Image.Ready
            text: tab.current === "" ? "Обои ещё не выбраны" : "Не удалось показать картинку"
            color: Colors.text
            opacity: 0.6
            font.family: Settings.uiFontFamily
            font.pixelSize: 13
        }

        // Подпись снизу на затемнённой плашке
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 32
            radius: Settings.r(16)
            color: Qt.rgba(0, 0, 0, 0.5)

            Text {
                anchors.centerIn: parent
                text: tab.busy ? "Применяю…" : "Нажми или перетащи картинку"
                color: "white"
                font.family: Settings.uiFontFamily
                font.pixelSize: 12
            }
        }

        // Рамка при наведении и при перетаскивании
        Rectangle {
            anchors.fill: parent
            radius: Settings.r(16)
            color: "transparent"
            border.width: drop.containsDrag ? 3 : previewMouse.containsMouse ? 2 : 0
            border.color: Colors.primary
        }

        MouseArea {
            id: previewMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: !tab.busy
            cursorShape: Qt.PointingHandCursor
            onClicked: tab.pick()
        }

        DropArea {
            id: drop
            anchors.fill: parent
            onDropped: event => {
                if (event.hasUrls && event.urls.length > 0 && !tab.busy)
                    tab.apply(decodeURIComponent(event.urls[0].toString().replace(/^file:\/\//, "")))
            }
        }
    }

    Text {
        Layout.fillWidth: true
        visible: tab.message !== ""
        text: tab.message
        color: Colors.error
        wrapMode: Text.WordWrap
        font.family: Settings.uiFontFamily
        font.pixelSize: 12
    }

    Item { Layout.fillHeight: true }
}
