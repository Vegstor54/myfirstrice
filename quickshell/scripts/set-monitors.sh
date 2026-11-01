#!/bin/bash
# Применяет раскладку мониторов из панели quickshell (Displays -> «Применить»).
# $1 — полный текст hypr/conf/monitors.lua (fallback Hyprland + основной монитор при старте)
# $2 — полный текст ~/.config/kanshi/config (профиль kanshi); пусто — файл kanshi не трогаем
#
# Оба файла собираются из одного черновика панели, поэтому не спорят друг с другом:
# kanshi применяет раскладку сам, а monitors.lua остаётся fallback — для загрузки без kanshi.
#
# Коды выхода: 0 — применил kanshi, 3 — kanshi не запущен, применил Hyprland, 1 — ошибка.

lua="$1"
kanshi_text="$2"

hypr_config="$HOME/.config/hypr/conf/monitors.lua"
kanshi_config="$HOME/.config/kanshi/config"

cache="$HOME/.cache"
mkdir -p "$cache"

# Защита от пустого или чужого текста: в конфиге должна быть хотя бы одна строка hl.monitor
case $lua in
    *"hl.monitor("*) ;;
    *) echo "Нет строк hl.monitor, конфиг не записан" >&2; exit 1 ;;
esac

# Пишем через временный файл рядом и переименовываем: Hyprland не увидит наполовину записанный конфиг
write_config() {
    local path=$1 text=$2 bak=$3
    mkdir -p "$(dirname "$path")"
    cp -f "$path" "$bak" 2>/dev/null
    local tmp
    tmp=$(mktemp "$path.XXXXXX") || return 1
    if printf '%s\n' "$text" > "$tmp" && mv -f "$tmp" "$path"; then
        return 0
    fi
    rm -f "$tmp"
    return 1
}

# Профиль kanshi: без него kanshi оставляем как есть (например, пустой второй аргумент)
if [ -n "$kanshi_text" ]; then
    case $kanshi_text in
        *"profile "*)
            write_config "$kanshi_config" "$kanshi_text" "$cache/kanshi.config.bak" \
                || { echo "Не удалось записать $kanshi_config" >&2; exit 1; }
            ;;
        *)
            echo "Нет профиля в конфиге kanshi, файл не записан" >&2
            exit 1
            ;;
    esac
fi

# fallback для Hyprland пишем всегда: без kanshi раскладка возьмётся отсюда
write_config "$hypr_config" "$lua" "$cache/monitors.lua.bak" \
    || { echo "Не удалось записать $hypr_config" >&2; exit 1; }

# Работающий kanshi перечитывает конфиг и применяет профиль сам:
# отдельный hyprctl reload не нужен, иначе мониторы перестроятся дважды
if command -v kanshictl >/dev/null 2>&1 && pgrep -x kanshi >/dev/null 2>&1; then
    if kanshictl reload >/dev/null 2>&1; then
        exit 0
    fi
fi

# kanshi не запущен или не умеет перечитывать конфиг — применяем правила Hyprland
hyprctl reload >/dev/null 2>&1 || { echo "hyprctl reload не сработал" >&2; exit 1; }
exit 3
