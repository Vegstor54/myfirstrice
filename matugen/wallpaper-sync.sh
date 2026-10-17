#!/usr/bin/env bash
# Ставит обои и генерирует палитру из них

CACHE="$HOME/.cache/current-wallpaper"
WALLPAPER="${1:-$(cat "$CACHE" 2>/dev/null)}"
WALLPAPER="${WALLPAPER:-$HOME/Pictures/wall.png}"

if [[ ! -f "$WALLPAPER" ]]; then
    echo "Usage: $0 <wallpaper-path>"
    exit 1
fi

echo "$WALLPAPER" > "$CACHE"

awww img "$WALLPAPER" --transition-type grow --transition-duration 1.5
matugen image "$WALLPAPER" --mode dark --prefer saturation
hyprctl reload

echo "Обои и цвета обновлены: $WALLPAPER"
