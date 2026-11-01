#!/bin/bash
# Записывает конфиг мониторов и применяет его.
# $1 — полный текст hypr/conf/monitors.lua (его собирает страница «Дисплеи» в панели).
config="$HOME/.config/hypr/conf/monitors.lua"
text=$1

# Защита от пустого или чужого текста: в конфиге должна быть хотя бы одна строка hl.monitor
case $text in
    *"hl.monitor("*) ;;
    *) echo "Нет строк hl.monitor, конфиг не записан"; exit 1 ;;
esac

# Прошлую версию храним в кэше (не в репозитории), чтобы можно было откатить руками
mkdir -p "$HOME/.cache"
cp -f "$config" "$HOME/.cache/monitors.lua.bak" 2>/dev/null

# Пишем через временный файл рядом и переименовываем: Hyprland не увидит наполовину записанный конфиг
tmp=$(mktemp "$config.XXXXXX") || exit 1
if printf '%s\n' "$text" > "$tmp" && mv -f "$tmp" "$config"; then
    hyprctl reload
else
    rm -f "$tmp"
    exit 1
fi
