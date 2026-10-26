import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import ".."

// Всплывающие карточки уведомлений в правом верхнем углу, под баром.
// Показываются на мониторе, на котором сейчас курсор (сфокусированный монитор Hyprland).
// Карточка сама исчезает через несколько секунд (срочные висят, пока их не закроют),
// пока на неё наведён курсор, таймер стоит. В историю уведомление попадает в любом случае.
Scope {
    id: root

    readonly property string focusedName: Hyprland.focusedMonitor?.name ?? ""

    Variants {
        // Окно только на одном мониторе: сфокусированном (или на первом, пока фокус неизвестен)
        model: Quickshell.screens.filter(s => root.focusedName === ""
                                              ? s === Quickshell.screens[0]
                                              : s.name === root.focusedName)

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            visible: NotificationState.popups.count > 0
            anchors { top: true; right: true }
            margins { top: Settings.barHeight + Settings.barTop + 8; right: Settings.barSideMargin }
            implicitWidth: 360
            implicitHeight: column.implicitHeight
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            // Top, а не Overlay: меню из QuickMenu и панель по SUPER+S остаются выше карточек
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "rice-notifications"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            Column {
                id: column
                width: parent.width
                spacing: 8

                Repeater {
                    model: NotificationState.popups

                    NotificationCard {
                        id: popupCard
                        required property int nid

                        notif: NotificationState.find(nid)
                        popup: true
                        width: column.width
                        // Карточка к этому моменту могла исчезнуть: пустую не показываем
                        visible: !!notif

                        opacity: 0
                        property real slide: 24
                        transform: Translate { x: popupCard.slide }
                        Component.onCompleted: { opacity = 1; slide = 0 }
                        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on slide { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                        onActivated: NotificationState.hidePopup(nid)

                        // Срочные не пропадают сами; остальные — через expireTimeout (в секундах) или 6 с
                        HoverHandler { id: hover }
                        Timer {
                            interval: popupCard.notif && popupCard.notif.expireTimeout > 0
                                      ? popupCard.notif.expireTimeout * 1000 : 6000
                            running: !popupCard.critical && !hover.hovered && popupCard.visible
                            onTriggered: NotificationState.hidePopup(popupCard.nid)
                        }
                    }
                }
            }
        }
    }
}
