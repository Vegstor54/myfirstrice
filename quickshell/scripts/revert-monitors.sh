#!/bin/bash
# Откат конфига мониторов, если применённые настройки не подтверждены.
#   watch    — ждёт срока из ~/.cache/monitors.pending и возвращает прошлые файлы (запускает set-monitors.sh)
#   now      — вернуть прошлые файлы сразу
#   confirm  — подтвердить текущий конфиг (снять ожидание)
#
# Откатываются оба файла, которые пишет панель: hypr/conf/monitors.lua и профиль kanshi,
# иначе при работающем kanshi откат ничего бы не менял — раскладку применял бы он.
config="$HOME/.config/hypr/conf/monitors.lua"
wconfig="$HOME/.config/kanshi/config"
backup="$HOME/.cache/monitors.lua.bak"
wbackup="$HOME/.cache/kanshi.config.bak"
pending="$HOME/.cache/monitors.pending"

# Вернуть файл из копии: через временный файл рядом, чтобы не остался наполовину записанный
restore_file() {
    local path=$1 bak=$2
    [ -f "$bak" ] || return 0
    mkdir -p "$(dirname "$path")"
    local tmp
    tmp=$(mktemp "$path.XXXXXX") || return 1
    if cp -f "$bak" "$tmp" && mv -f "$tmp" "$path"; then
        return 0
    fi
    rm -f "$tmp"
    return 1
}

restore() {
    restore_file "$config" "$backup"
    restore_file "$wconfig" "$wbackup"
    # Применяем тем же способом, каким применяли: сначала kanshi, иначе правила Hyprland
    if command -v kanshictl >/dev/null 2>&1 && pgrep -x kanshi >/dev/null 2>&1; then
        kanshictl reload >/dev/null 2>&1 && { rm -f "$pending"; return 0; }
    fi
    hyprctl reload
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
