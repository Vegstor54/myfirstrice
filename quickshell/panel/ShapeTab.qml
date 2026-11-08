import QtQuick
import QtQuick.Layouts
import ".."

// Форма: скругление бара и остального интерфейса настраиваются отдельно.
// Бар: скруглённый «плавает» с отступами, прямой занимает всю верхнюю кромку экрана.
// Интерфейс: панель, меню значков и часов, уведомления, плитки, кнопки и ползунки.
ColumnLayout {
    id: tab
    spacing: 16

    Text {
        text: "Бар"
        color: Colors.text
        font.family: Settings.uiFontFamily
        font.pixelSize: 14
        font.bold: true
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        BarChip {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            label: "Скруглённый"
            selected: Settings.barRounded
            onClicked: Settings.barRounded = true
        }
        BarChip {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            label: "Прямой, во всю ширину"
            selected: !Settings.barRounded
            onClicked: Settings.barRounded = false
        }
    }

    Text {
        text: "Положение бара"
        color: Colors.text
        font.family: Settings.uiFontFamily
        font.pixelSize: 14
        font.bold: true
    }

    // Отдельно от формы: прижимает сплошной бар к краям экрана, элементы внутри остаются скруглёнными или прямыми по форме
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        BarChip {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            label: "Плавающий"
            selected: !Settings.barAttached
            onClicked: Settings.barAttached = false
        }
        BarChip {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            label: "К краям экрана"
            selected: Settings.barAttached
            onClicked: Settings.barAttached = true
        }
    }

    Text {
        Layout.fillWidth: true
        text: "«К краям экрана» работает в стиле «Сплошной»: бар занимает всю верхнюю кромку без отступов. У «Островов» общей подложки нет, поэтому они всегда плавают."
        wrapMode: Text.WordWrap
        color: Colors.text
        opacity: 0.7
        font.family: Settings.uiFontFamily
        font.pixelSize: 13
    }

    Text {
        text: "Интерфейс"
        color: Colors.text
        font.family: Settings.uiFontFamily
        font.pixelSize: 14
        font.bold: true
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        BarChip {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            label: "Скруглённый"
            selected: Settings.uiRounded
            onClicked: Settings.uiRounded = true
        }
        BarChip {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            label: "Прямой"
            selected: !Settings.uiRounded
            onClicked: Settings.uiRounded = false
        }
    }

    Text {
        Layout.fillWidth: true
        text: "Бар и интерфейс меняются независимо: например, прямой бар во всю ширину и скруглённые меню."
        wrapMode: Text.WordWrap
        color: Colors.text
        opacity: 0.7
        font.family: Settings.uiFontFamily
        font.pixelSize: 13
    }

    Item { Layout.fillHeight: true }
}
