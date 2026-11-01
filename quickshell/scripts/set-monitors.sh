#!/bin/bash
# Записывает конфиг мониторов и применяет его.
# $1 — полный текст hypr/conf/monitors.lua (его собирает страница «Дисплеи» в панели).
# После применения у владельца есть MONITORS_CONFIRM_SECONDS (15) секунд подтвердить результат:
# наблюдатель revert-monitors.sh сам вернёт прошлый конфиг, если подтверждения не будет.
config="$HOME/.config/hypr/conf/monitors.lua"
backup="$HOME/.cache/monitors.lua.bak"
pending="$HOME/.cache/monitors.pending"
text=$1

# Защита от пустого или чужого текста: в конфиге должна быть хотя бы одна строка hl.monitor
case $text in
    *"hl.monitor("*) ;;
    *) echo "Нет строк hl.monitor, конфиг не записан"; exit 1 ;;
esac

# Прошлую версию храним в кэше (не в репозитории). Пока предыдущее применение не подтверждено,
# копию не трогаем: откат должен вести к последнему подтверждённому конфигу
mkdir -p "$HOME/.cache"
[ -f "$pending" ] || cp -f "$config" "$backup" 2>/dev/null

# Пишем через временный файл рядом и переименовываем: Hyprland не увидит наполовину записанный конфиг
tmp=$(mktemp "$config.XXXXXX") || exit 1
if printf '%s\n' "$text" > "$tmp" && mv -f "$tmp" "$config"; then
    hyprctl reload
else
    rm -f "$tmp"
    exit 1
fi

# Конфиг изменился: ждём подтверждения, иначе наблюдатель вернёт прошлый
if [ -f "$backup" ] && ! cmp -s "$backup" "$config"; then
    echo $(( $(date +%s) + ${MONITORS_CONFIRM_SECONDS:-15} )) > "$pending"
    setsid nohup "$(dirname "$0")/revert-monitors.sh" watch >/dev/null 2>&1 &
else
    rm -f "$pending"
fi
exit 0
