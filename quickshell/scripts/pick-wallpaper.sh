#!/bin/bash
# Диалог выбора картинки. Печатает выбранный путь; пусто, если диалог закрыли.
# Код выхода 2: не установлена ни одна программа для диалога (нужен zenity или kdialog).

start="$HOME/Pictures"
[ -d "$start" ] || start="$HOME"

if command -v zenity >/dev/null 2>&1; then
    zenity --file-selection --title="Выбор обоев" --filename="$start/" \
        --file-filter='Изображения | *.png *.jpg *.jpeg *.webp *.bmp *.gif *.PNG *.JPG *.JPEG *.WEBP'
elif command -v kdialog >/dev/null 2>&1; then
    kdialog --title "Выбор обоев" --getopenfilename "$start" \
        'image/png image/jpeg image/webp image/bmp image/gif'
else
    exit 2
fi
