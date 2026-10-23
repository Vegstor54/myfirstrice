pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick

// Менеджер уведомлений: Quickshell сам занимает имя org.freedesktop.Notifications на D-Bus
// и заменяет mako/dunst/swaync. Одновременно может работать только один демон уведомлений,
// поэтому остальные (mako, dunst, swaync) должны быть выключены.
//
// Один экземпляр на всю оболочку:
//   history  — все ещё не закрытые уведомления, новые первыми (вкладка «Уведомления»)
//   popups   — какие уведомления сейчас показаны всплывающими карточками (NotificationPopups)
//   dnd      — режим «не беспокоить» (хранится в Settings): всплывающие карточки не показываются,
//              но уведомления попадают в историю; срочные (critical) показываются всё равно
Singleton {
    id: root

    // Не закрытые пользователем уведомления, новые первыми
    readonly property var history: {
        const v = server.trackedNotifications.values
        const out = []
        for (let i = v.length - 1; i >= 0; i--) out.push(v[i])
        return out
    }
    readonly property int count: server.trackedNotifications.values.length

    readonly property bool dnd: Settings.dnd
    function setDnd(on) { Settings.dnd = on }
    function toggleDnd() { Settings.dnd = !Settings.dnd }

    // Список id уведомлений, показанных всплывающими карточками (в порядке появления)
    property alias popups: popupModel
    ListModel { id: popupModel }

    // Ищет уведомление по id среди ещё не закрытых; null, если его уже нет
    function find(nid) {
        const v = server.trackedNotifications.values
        for (let i = 0; i < v.length; i++)
            if (v[i].id === nid) return v[i]
        return null
    }

    function popupIndex(nid) {
        for (let i = 0; i < popupModel.count; i++)
            if (popupModel.get(i).nid === nid) return i
        return -1
    }

    // Убирает всплывающую карточку, но оставляет уведомление в истории
    function hidePopup(nid) {
        const i = popupIndex(nid)
        if (i >= 0) popupModel.remove(i)
        // «Мимолётные» уведомления (transient) в историю не нужны
        const n = find(nid)
        if (n && n.transient) n.expire()
    }

    // Закрывает уведомление совсем: пропадает и из истории
    function dismiss(n) {
        if (n) n.dismiss()
    }

    function clearAll() {
        const v = server.trackedNotifications.values
        const all = []
        for (let i = 0; i < v.length; i++) all.push(v[i])
        for (const n of all) n.dismiss()
    }

    // Нажатие на карточку: вызывает действие по умолчанию (приложение обычно выводит своё окно)
    function invokeDefault(n) {
        if (!n) return false
        for (let i = 0; i < n.actions.length; i++) {
            if (n.actions[i].identifier === "default") {
                n.actions[i].invoke()
                return true
            }
        }
        return false
    }

    // Убирает из всплывающих те, которых уже нет (закрыты приложением или пользователем)
    function prunePopups() {
        for (let i = popupModel.count - 1; i >= 0; i--) {
            if (!find(popupModel.get(i).nid)) popupModel.remove(i)
        }
    }

    NotificationServer {
        id: server

        // Что мы умеем показывать: приложения подстроят уведомления под это
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: false
        imageSupported: true
        persistenceSupported: true
        // Уведомления переживают перезагрузку конфигурации Quickshell (после смены обоев она случается)
        keepOnReload: true

        onNotification: notification => {
            // Без этого уведомление не хранится и пропадает сразу
            notification.tracked = true

            // Приложение заменило своё уведомление (тот же id): карточка должна появиться заново
            const old = root.popupIndex(notification.id)
            if (old >= 0) popupModel.remove(old)

            if (!root.dnd || notification.urgency === NotificationUrgency.Critical)
                popupModel.append({ nid: notification.id })
        }
    }

    Connections {
        target: server.trackedNotifications
        function onValuesChanged() { root.prunePopups() }
    }

    // Из бинда или терминала: quickshell ipc call notifications toggleDnd
    IpcHandler {
        target: "notifications"
        function toggleDnd(): void { root.toggleDnd() }
        function clear(): void { root.clearAll() }
    }
}
