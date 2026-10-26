#!/usr/bin/env bash
# Ставит обои и генерирует палитру из них (в сохранённом режиме тёмной/светлой темы, см. apply-theme.sh)

CACHE="$HOME/.cache/current-wallpaper"
WALLPAPER="${1:-$(cat "$CACHE" 2>/dev/null)}"
WALLPAPER="${WALLPAPER:-$HOME/Pictures/wall.png}"

if [[ ! -f "$WALLPAPER" ]]; then
    echo "Usage: $0 <wallpaper-path>"
    exit 1
fi

echo "$WALLPAPER" > "$CACHE"

awww img "$WALLPAPER" --transition-type grow --transition-duration 1.5
bash "$(dirname "$(readlink -f "$0")")/apply-theme.sh" || exit 1

echo "Обои и цвета обновлены: $WALLPAPER"
