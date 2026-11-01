#!/bin/bash
# Применяет раскладку мониторов из панели quickshell (Displays -> «Применить»).
# $1 — полный текст hypr/conf/monitors.lua (fallback Hyprland + основной монитор при старте)
# $2 — полный текст ~/.config/kanshi/config (профиль kanshi); пусто — файл kanshi не трогаем
#
# Оба файла собираются из одного черновика панели, поэтому не спорят друг с другом:
# kanshi применяет раскладку сам, а monitors.lua остаётся fallback — для загрузки без kanshi.
#
# После применения есть MONITORS_CONFIRM_SECONDS (15) секунд подтвердить результат:
# наблюдатель revert-monitors.sh вернёт оба прежних файла, если подтверждения не будет.
#
# Коды выхода: 0 — применил kanshi, 3 — kanshi не запущен, применил Hyprland, 1 — ошибка.

lua="$1"
kanshi_text="$2"

hypr_config="$HOME/.config/hypr/conf/monitors.lua"
kanshi_config="$HOME/.config/kanshi/config"

cache="$HOME/.cache"
hypr_backup="$cache/monitors.lua.bak"
kanshi_backup="$cache/kanshi.config.bak"
pending="$cache/monitors.pending"
mkdir -p "$cache"

# Защита от пустого или чужого текста: в конфиге должна быть хотя бы одна строка hl.monitor
case $lua in
    *"hl.monitor("*) ;;
    *) echo "Нет строк hl.monitor, конфиг не записан" >&2; exit 1 ;;
esac

# Прошлые версии храним в кэше (не в репозитории), но пока предыдущее применение не подтверждено,
# копии не трогаем: откат должен вести к последнему подтверждённому конфигу, а не к промежуточному
if [ ! -f "$pending" ]; then
    cp -f "$hypr_config" "$hypr_backup" 2>/dev/null
    cp -f "$kanshi_config" "$kanshi_backup" 2>/dev/null
fi

# Пишем через временный файл рядом и переименовываем: Hyprland не увидит наполовину записанный конфиг
write_config() {
    local path=$1 text=$2
    mkdir -p "$(dirname "$path")"
    local tmp
    tmp=$(mktemp "$path.XXXXXX") || return 1
    if printf '%s\n' "$text" > "$tmp" && mv -f "$tmp" "$path"; then
        return 0
    fi
    rm -f "$tmp"
    return 1
}

# Профиль kanshi: пустой второй аргумент — файл kanshi не трогаем
if [ -n "$kanshi_text" ]; then
    case $kanshi_text in
        *"profile "*) ;;
        *)
            echo "Нет профиля в конфиге kanshi, файл не записан" >&2
            exit 1
            ;;
    esac
    write_config "$kanshi_config" "$kanshi_text" \
        || { echo "Не удалось записать $kanshi_config" >&2; exit 1; }
fi

# fallback для Hyprland пишем всегда: без kanshi раскладка возьмётся отсюда
write_config "$hypr_config" "$lua" \
    || { echo "Не удалось записать $hypr_config" >&2; exit 1; }

# Работающий kanshi перечитывает конфиг и применяет профиль сам:
# отдельный hyprctl reload не нужен, иначе мониторы перестроятся дважды
code=3
if command -v kanshictl >/dev/null 2>&1 && pgrep -x kanshi >/dev/null 2>&1; then
    if kanshictl reload >/dev/null 2>&1; then
        code=0
    fi
fi

# kanshi не запущен или не умеет перечитывать конфиг — применяем правила Hyprland
if [ "$code" -ne 0 ]; then
    hyprctl reload >/dev/null 2>&1 || { echo "hyprctl reload не сработал" >&2; exit 1; }
fi

# Конфиг изменился: ждём подтверждения, иначе наблюдатель вернёт прежние файлы
changed=0
if [ -f "$hypr_backup" ] && ! cmp -s "$hypr_backup" "$hypr_config"; then
    changed=1
fi
if [ -n "$kanshi_text" ] && [ -f "$kanshi_backup" ] && ! cmp -s "$kanshi_backup" "$kanshi_config"; then
    changed=1
fi
if [ "$changed" = 1 ]; then
    echo $(( $(date +%s) + ${MONITORS_CONFIRM_SECONDS:-15} )) > "$pending"
    setsid nohup "$(dirname "$0")/revert-monitors.sh" watch >/dev/null 2>&1 &
else
    rm -f "$pending"
fi
exit "$code"
