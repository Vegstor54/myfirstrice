#!/usr/bin/env bash
# Установка райса на Arch Linux: пакеты, ссылки из ~/.config на этот репозиторий, служба Bluetooth.
#
#   bash install.sh                       пакеты + ссылки + Bluetooth
#   bash install.sh --wallpaper ~/a.png   то же и первая палитра из обоев
#   bash install.sh --optional            ещё необязательные пакеты (packages/optional.txt)
#   bash install.sh --no-packages         только ссылки (подходит не только Arch)
#   bash install.sh --dry-run             ничего не менять, показать, что будет сделано
#   bash install.sh --yes                 не задавать вопросов
#
# Скрипт можно запускать повторно: что уже сделано, пропускается.
# Папки в ~/.config, которые уже есть, не удаляются: переезжают в <имя>.bak-<дата>.

set -u

REPO="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
DIRS=(hypr matugen quickshell kitty qt6ct)

want_packages=1 want_optional=0 dry=0 yes=0 wallpaper=""

while [ $# -gt 0 ]; do
    case $1 in
        --no-packages) want_packages=0 ;;
        --optional)    want_optional=1 ;;
        --dry-run)     dry=1 ;;
        --yes|-y)      yes=1 ;;
        --wallpaper)   shift; wallpaper="${1:-}" ;;
        -h|--help)     sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *)             echo "Неизвестный ключ: $1 (справка: --help)"; exit 2 ;;
    esac
    shift
done

say()  { printf '\n==> %s\n' "$*"; }
note() { printf '    %s\n' "$*"; }
# Выполняет команду или только показывает её в режиме --dry-run
run()  { if [ "$dry" = 1 ]; then note "[dry-run] $*"; else "$@"; fi; }
ask()  {
    [ "$yes" = 1 ] && return 0
    [ "$dry" = 1 ] && return 0
    read -r -p "    $1 [y/N] " a
    [ "$a" = y ] || [ "$a" = Y ]
}

# Имена пакетов из списка (без комментариев и пустых строк)
read_list() { sed 's/#.*//' "$1" | awk 'NF{print $1}'; }

# ---------------------------------------------------------------- пакеты
install_packages() {
    if [ ! -f /etc/arch-release ]; then
        echo "Установка пакетов рассчитана на Arch Linux. Для ссылок без пакетов: bash install.sh --no-packages"
        exit 1
    fi

    local list=("$REPO/packages/required.txt")
    [ "$want_optional" = 1 ] && list+=("$REPO/packages/optional.txt")

    local official=() aur=() p
    while read -r p; do
        if pacman -Si "$p" >/dev/null 2>&1; then official+=("$p"); else aur+=("$p"); fi
    done < <(for f in "${list[@]}"; do read_list "$f"; done | sort -u)

    say "Пакеты из официальных репозиториев (${#official[@]})"
    note "${official[*]:-—}"
    if [ ${#official[@]} -gt 0 ]; then
        run sudo pacman -S --needed "${official[@]}" || echo "    pacman завершился с ошибкой, продолжаю"
    fi

    say "Пакеты из AUR (${#aur[@]})"
    note "${aur[*]:-—}"
    if [ ${#aur[@]} -gt 0 ]; then
        local helper=""
        command -v yay  >/dev/null 2>&1 && helper=yay
        [ -z "$helper" ] && command -v paru >/dev/null 2>&1 && helper=paru
        if [ -n "$helper" ]; then
            run "$helper" -S --needed "${aur[@]}" || echo "    $helper завершился с ошибкой, продолжаю"
        else
            echo "    Нет yay и paru. Поставьте AUR-хелпер и выполните: yay -S --needed ${aur[*]}"
        fi
    fi
}

# ---------------------------------------------------------------- ссылки
link_configs() {
    say "Ссылки из $CONFIG на $REPO"
    mkdir -p "$CONFIG"
    local d src dst stamp
    stamp="$(date +%Y%m%d-%H%M%S)"
    for d in "${DIRS[@]}"; do
        src="$REPO/$d"
        dst="$CONFIG/$d"
        if [ ! -d "$src" ]; then note "$d: в репозитории нет такой папки, пропускаю"; continue; fi
        if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
            note "$d: уже ссылка на репозиторий"
            continue
        fi
        if [ -e "$dst" ] || [ -L "$dst" ]; then
            # Не ln -sfn поверх папки: ссылка создалась бы внутри неё
            note "$d: уже есть, переношу в $d.bak-$stamp"
            run mv "$dst" "$dst.bak-$stamp"
        fi
        run ln -s "$src" "$dst"
        note "$d: ссылка создана"
    done

    # Скрипты оболочки Quickshell запускает напрямую
    local f
    for f in "$REPO"/quickshell/scripts/*.sh; do
        [ -x "$f" ] || { run chmod +x "$f"; note "chmod +x $(basename "$f")"; }
    done
}

# ---------------------------------------------------------------- службы
enable_services() {
    command -v systemctl >/dev/null 2>&1 || return 0
    say "Служба Bluetooth"
    if systemctl is-enabled bluetooth.service >/dev/null 2>&1; then
        note "bluetooth.service уже включена"
    elif [ -f /usr/lib/systemd/system/bluetooth.service ] || [ "$dry" = 1 ]; then
        if ask "Включить bluetooth.service (sudo systemctl enable --now bluetooth)?"; then
            run sudo systemctl enable --now bluetooth.service
        else
            note "пропущено; без неё значок и вкладка Bluetooth в баре скрыты"
        fi
    else
        note "bluez не установлен, пропускаю"
    fi
}

# ---------------------------------------------------------------- палитра
first_palette() {
    say "Цветовая палитра"
    if [ -n "$wallpaper" ]; then
        if [ -f "$wallpaper" ]; then
            run bash "$CONFIG/matugen/wallpaper-sync.sh" "$wallpaper"
        else
            echo "    Файл обоев не найден: $wallpaper"
        fi
    elif [ -f "$REPO/quickshell/Colors.qml" ]; then
        note "палитра уже создана"
    else
        note "палитры ещё нет, её создаёт matugen из обоев. Выполните:"
        note "bash ~/.config/matugen/wallpaper-sync.sh /путь/к/обоям.png"
    fi
}

[ "$dry" = 1 ] && echo "Режим --dry-run: ничего не меняю."
[ "$want_packages" = 1 ] && install_packages
link_configs
[ "$want_packages" = 1 ] && enable_services
first_palette

say "Готово"
note "Выйдите из сессии и зайдите снова (нужно для Qt-темы и конфига Hyprland), затем запустите Hyprland."
note "Панель настроек: SUPER+S, лаунчер: SUPER+Space."
