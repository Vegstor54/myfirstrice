#!/bin/bash
# Управление питанием: power.sh suspend|hibernate|poweroff
# Код выхода 2: гибернация недоступна (нет swap или не настроен resume).

notify() {
    command -v notify-send >/dev/null 2>&1 && notify-send -a "Quickshell" "$1" "$2"
}

case $1 in
    suspend)
        systemctl suspend
        ;;
    hibernate)
        if [ "$(systemctl can-hibernate 2>/dev/null)" != "yes" ]; then
            notify "Гибернация недоступна" "Нужен swap не меньше объёма ОЗУ и resume= в загрузчике"
            echo "hibernate is not available" >&2
            exit 2
        fi
        systemctl hibernate
        ;;
    poweroff)
        systemctl poweroff
        ;;
    *)
        echo "Usage: $0 suspend|hibernate|poweroff" >&2
        exit 1
        ;;
esac
