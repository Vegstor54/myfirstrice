#!/bin/bash
# Откат конфига мониторов, если применённые настройки не подтверждены.
#   watch    — ждёт срока из ~/.cache/monitors.pending и возвращает прошлый конфиг (запускает set-monitors.sh)
#   now      — вернуть прошлый конфиг сразу
#   confirm  — подтвердить текущий конфиг (снять ожидание)
config="$HOME/.config/hypr/conf/monitors.lua"
backup="$HOME/.cache/monitors.lua.bak"
pending="$HOME/.cache/monitors.pending"

restore() {
    if [ -f "$backup" ]; then
        tmp=$(mktemp "$config.XXXXXX") || exit 1
        if cp -f "$backup" "$tmp" && mv -f "$tmp" "$config"; then
            hyprctl reload
        else
            rm -f "$tmp"
        fi
    fi
    rm -f "$pending"
}

case $1 in
    confirm)
        rm -f "$pending"
        ;;
    now)
        restore
        ;;
    watch)
        # Наблюдатель живёт, пока ожидание то же самое: новое применение пишет другой срок,
        # и старый наблюдатель выходит, а подтверждение или откат удаляют файл
        deadline=$(cat "$pending" 2>/dev/null) || exit 0
        while [ -f "$pending" ] && [ "$(cat "$pending" 2>/dev/null)" = "$deadline" ]; do
            if [ "$(date +%s)" -ge "$deadline" ]; then
                restore
                exit 0
            fi
            sleep 0.5
        done
        ;;
    *)
        echo "Использование: $0 watch|now|confirm" >&2
        exit 2
        ;;
esac
