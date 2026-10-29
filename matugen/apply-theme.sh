#!/usr/bin/env bash
# Применяет тему: считает палитру matugen и переключает тёмную/светлую тему у приложений.
# Использование: apply-theme.sh [wallpaper|dark|light]
#   wallpaper — палитра из текущих обоев (тёмная);
#   dark  — чёрный фон, белый текст и акценты, без цвета (монохромная схема matugen);
#   light — белый фон, чёрный текст и акценты, без цвета.
#   dark и light от обоев не зависят.
#   Без аргумента берёт сохранённый режим (~/.cache/theme-mode, по умолчанию wallpaper).
#   Обои не меняет: их ставит wallpaper-sync.sh.
#
#   Quickshell, kitty, Hyprland — палитра matugen (см. config.toml).
#   Qt-приложения — через qt6ct: matugen пишет ему цветовую схему, тут включается её использование.
#   GTK-приложения и браузеры — через gsettings (color-scheme для GTK4, libadwaita и браузеров, gtk-theme для GTK3).

MODE_FILE="$HOME/.cache/theme-mode"
WALLPAPER_FILE="$HOME/.cache/current-wallpaper"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# Исходный цвет для фиксированных тем dark и light. Схема монохромная, поэтому цвет на результат не влияет
FIXED_SOURCE="#808080"

mode="${1:-$(cat "$MODE_FILE" 2>/dev/null)}"
case $mode in
    wallpaper|dark|light) ;;
    *) mode=wallpaper ;;
esac

# matugen пишет цветовую схему в эту папку, но сам её не создаёт
mkdir -p "$CONFIG_HOME/qt6ct/colors"

if [[ $mode == wallpaper ]]; then
    WALLPAPER="$(cat "$WALLPAPER_FILE" 2>/dev/null)"
    WALLPAPER="${WALLPAPER:-$HOME/Pictures/wall.png}"
    if [[ ! -f "$WALLPAPER" ]]; then
        echo "Нет обоев для палитры: $WALLPAPER" >&2
        exit 1
    fi
    matugen image "$WALLPAPER" --mode dark --prefer saturation || exit 1
else
    matugen color hex "$FIXED_SOURCE" --mode "$mode" --type scheme-monochrome || exit 1
fi
# Режим запоминаем только после успешной генерации палитры
echo "$mode" > "$MODE_FILE"

# --- Qt: qt6ct должен брать цветовую схему matugen ---
# Меняет только свои ключи в [Appearance], остальные настройки qt6ct (шрифты и т.д.) не трогает.
ini_set() {
    python3 - "$1" "$2" "$3" "$4" <<'PY'
import sys
path, section, key, value = sys.argv[1:5]
try:
    lines = open(path, encoding="utf-8").read().split("\n")
except FileNotFoundError:
    lines = []
header = "[%s]" % section
start = next((i for i, l in enumerate(lines) if l.strip() == header), None)
if start is None:
    lines = [l for l in lines if l != ""] + ([""] if lines else []) + [header, "%s=%s" % (key, value), ""]
else:
    end = next((i for i in range(start + 1, len(lines)) if lines[i].startswith("[")), len(lines))
    for i in range(start + 1, end):
        if lines[i].split("=", 1)[0].strip() == key:
            lines[i] = "%s=%s" % (key, value)
            break
    else:
        lines.insert(start + 1, "%s=%s" % (key, value))
open(path, "w", encoding="utf-8").write("\n".join(lines))
PY
}
QT6CT_CONF="$CONFIG_HOME/qt6ct/qt6ct.conf"
ini_set "$QT6CT_CONF" Appearance color_scheme_path "$CONFIG_HOME/qt6ct/colors/matugen.conf"
ini_set "$QT6CT_CONF" Appearance custom_palette true
grep -q '^style=' "$QT6CT_CONF" || ini_set "$QT6CT_CONF" Appearance style Fusion

# --- GTK и браузеры ---
if command -v gsettings >/dev/null 2>&1; then
    if [[ $mode == light ]]; then
        scheme=prefer-light
        theme=Adwaita
    else
        scheme=prefer-dark
        theme=Adwaita-dark
    fi
    timeout 3 gsettings set org.gnome.desktop.interface color-scheme "$scheme" 2>/dev/null
    # Adwaita-dark есть в gnome-themes-extra; если его нет, GTK3-приложения останутся светлыми
    timeout 3 gsettings set org.gnome.desktop.interface gtk-theme "$theme" 2>/dev/null
fi

hyprctl reload
echo "Тема применена: $mode"
