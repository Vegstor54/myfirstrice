#!/bin/bash
# Скриншот через grim + slurp + wl-copy.
# Использование: screenshot.sh region|screen|all|window
#   region — выбранная мышью область (Esc отменяет)
#   screen — монитор, на котором сейчас фокус
#   all    — все мониторы целиком
#   window — активное окно
# Снимок сохраняется в ~/Pictures/Screenshots, копируется в буфер обмена, приходит уведомление.
# Пакеты: grim, slurp (только для region), wl-clipboard.
# Необязательно: wayfreeze (AUR) замораживает экран на время выбора области.
mode=${1:-region}

# Только один экземпляр: пока идёт выбор области, повторный запуск (скриншот в скриншоте) игнорируется
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/screenshot.lock"
flock -n 9 || exit 0

notify() {
    command -v notify-send >/dev/null 2>&1 && notify-send -a "Скриншот" "$@"
}

# Каких программ не хватает: команда -> пакет
missing=""
need() {
    command -v "$1" >/dev/null 2>&1 || missing="$missing $2"
}
need grim grim
need wl-copy wl-clipboard
[ "$mode" = region ] && need slurp slurp
if [ -n "$missing" ]; then
    notify "Скриншот не сделан" "Не хватает пакетов:$missing (pacman -S$missing)"
    exit 2
fi

dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$dir"
file="$dir/screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"

case $mode in
    region)
        # slurp возвращает ошибку, если выбор отменили: тогда молча выходим
        freeze_pid=""
        if command -v wayfreeze >/dev/null 2>&1; then
            wayfreeze &
            freeze_pid=$!
            sleep 0.15
        fi
        geom=$(slurp -w 2 -b '#00000066')
        rc=$?
        if [ $rc -eq 0 ]; then grim -g "$geom" "$file"; fi
        [ -n "$freeze_pid" ] && kill "$freeze_pid" 2>/dev/null
        [ $rc -eq 0 ] || exit 0
        ;;
    screen)
        out=$(hyprctl monitors | awk '/^Monitor /{n=$2} /focused: yes/{print n; exit}')
        if [ -n "$out" ]; then grim -o "$out" "$file"; else grim "$file"; fi
        ;;
    all)
        grim "$file"
        ;;
    window)
        info=$(hyprctl activewindow)
        at=$(printf '%s\n' "$info" | awk '$1 == "at:" {print $2; exit}')
        size=$(printf '%s\n' "$info" | awk '$1 == "size:" {print $2; exit}')
        if [ -z "$at" ] || [ -z "$size" ]; then
            notify "Скриншот не сделан" "Нет активного окна"
            exit 1
        fi
        grim -g "$at ${size/,/x}" "$file"
        ;;
    *)
        echo "Использование: $0 region|screen|all|window" >&2
        exit 1
        ;;
esac

if [ ! -s "$file" ]; then
    rm -f "$file"
    notify "Скриншот не сделан" "grim не создал файл"
    exit 1
fi

wl-copy --type image/png < "$file"
notify -i "$file" "Скриншот сохранён" "$(basename "$file")"
