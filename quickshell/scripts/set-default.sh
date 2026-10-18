#!/bin/bash
category=$1
app=$2
config="$HOME/.config/hypr/conf/programs.lua"
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
apps_dir="$data_home/applications"
editor_desktop="default-editor.desktop"

# Где искать .desktop-файлы приложений
IFS=: read -ra data_dirs <<< "${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
desktop_dirs=("$apps_dir")
for d in "${data_dirs[@]}"; do desktop_dirs+=("$d/applications"); done
desktop_dirs+=(/var/lib/flatpak/exports/share/applications "$data_home/flatpak/exports/share/applications")

[ -z "$app" ] && exit 1

case $category in
    terminal)    var_name="terminal" ;;
    filemanager) var_name="fileManager" ;;
    browser)     var_name="browser" ;;
    editor)      var_name="editor" ;;
    *) echo "Unknown category: $category"; exit 1 ;;
esac

# Читает значение переменной из programs.lua (тот же формат, что в get-default.sh)
read_var() {
    grep -m1 "^local $1[[:space:]]*=" "$config" | sed 's/.*"\(.*\)".*/\1/'
}

# Создаёт ярлык редактора и назначает его для текстовых файлов.
# Terminal=true не используем: GLib/Nautilus часто не находят терминал.
# Вместо этого ярлык сам запускает выбранный терминал с выбранным редактором.
sync_editor_assoc() {
    local terminal editor run exec_line
    local mimes=(
        text/plain text/markdown text/x-log
        text/x-lua text/x-python text/x-java text/x-makefile
        text/x-csrc text/x-chdr text/x-c++src
        text/x-shellscript application/x-shellscript
        application/json application/toml application/yaml
    )

    terminal=$(read_var terminal)
    editor=$(read_var editor)
    [ -z "$editor" ] && return

    case $editor in
        emacs)
            # GUI-редактор: терминал не нужен
            exec_line="$editor %F"
            ;;
        *)
            [ -z "$terminal" ] && return
            case $terminal in
                wezterm) run="wezterm start --" ;;
                foot)    run="foot" ;;
                *)       run="$terminal -e" ;;
            esac
            exec_line="$run $editor %F"
            ;;
    esac

    local mime_list
    mime_list=$(printf '%s;' "${mimes[@]}")

    mkdir -p "$apps_dir"
    cat > "$apps_dir/$editor_desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Default editor ($editor)
Exec=$exec_line
Terminal=false
MimeType=$mime_list
EOF

    update-desktop-database "$apps_dir" 2>/dev/null
    for t in "${mimes[@]}"; do
        xdg-mime default "$editor_desktop" "$t"
    done
}

# Ищет .desktop-файл программы по имени её команды.
# $1 - команда (kitty, nautilus, firefox...), $2 - regex, который должен быть в файле
# (тип MIME или категория), чтобы не взять служебный ярлык вроде kitty-open.desktop.
# Печатает имя файла (id для xdg-mime) или возвращает 1, если ничего не нашлось.
find_desktop() {
    local bin=$1 pattern=$2 dir f

    # Сначала точное совпадение имени: firefox -> firefox.desktop
    for dir in "${desktop_dirs[@]}"; do
        f="$dir/$bin.desktop"
        if [ -e "$f" ] && grep -qE "$pattern" "$f"; then
            basename "$f"
            return 0
        fi
    done

    # Иначе ищем по команде в Exec= (nautilus -> org.gnome.Nautilus.desktop),
    # пропуская скрытые ярлыки и ярлыки для конкретных окружений
    for dir in "${desktop_dirs[@]}"; do
        [ -d "$dir" ] || continue
        for f in "$dir"/*.desktop; do
            [ -e "$f" ] || continue
            grep -qE '^(NoDisplay=true|OnlyShowIn=)' "$f" && continue
            grep -qE "^Exec=(env [^ =]+=[^ ]+ )?([^ ]*/)?${bin}( |$)" "$f" || continue
            grep -qE "$pattern" "$f" || continue
            basename "$f"
            return 0
        done
    done
    return 1
}

# Браузер: ссылки и HTML-файлы
sync_browser_assoc() {
    local id t
    if ! id=$(find_desktop "$app" 'x-scheme-handler/http'); then
        echo "Не нашёл .desktop-файл браузера $app, ассоциации не менялись" >&2
        return
    fi
    for t in x-scheme-handler/http x-scheme-handler/https text/html application/xhtml+xml; do
        xdg-mime default "$id" "$t"
    done
}

# Файловый менеджер: открытие папок
sync_filemanager_assoc() {
    local id
    if ! id=$(find_desktop "$app" 'inode/directory'); then
        echo "Не нашёл .desktop-файл файлового менеджера $app, ассоциации не менялись" >&2
        return
    fi
    xdg-mime default "$id" inode/directory
}

# Терминал: по этому списку система (xdg-terminal-exec, GLib) выбирает терминал
# для приложений с Terminal=true, а gsettings читают GNOME-приложения вроде Nautilus
sync_terminal_assoc() {
    local id arg
    if id=$(find_desktop "$app" 'TerminalEmulator'); then
        mkdir -p "$config_home"
        printf '%s\n' "$id" > "$config_home/xdg-terminals.list"
        xdg-mime default "$id" x-scheme-handler/terminal
    else
        echo "Не нашёл .desktop-файл терминала $app, xdg-terminals.list не менялся" >&2
    fi

    if command -v gsettings >/dev/null 2>&1; then
        case $app in
            wezterm) arg="start" ;;
            foot)    arg="" ;;
            *)       arg="-e" ;;
        esac
        timeout 3 gsettings set org.gnome.desktop.default-applications.terminal exec "$app" 2>/dev/null
        timeout 3 gsettings set org.gnome.desktop.default-applications.terminal exec-arg "$arg" 2>/dev/null
    fi
}

sed -i "s|^local $var_name[[:space:]]*=.*|local $var_name = \"$app\"|" "$config"

case $category in
    editor)      sync_editor_assoc ;;
    terminal)    sync_terminal_assoc; sync_editor_assoc ;;  # ярлык редактора зависит и от терминала
    browser)     sync_browser_assoc ;;
    filemanager) sync_filemanager_assoc ;;
esac

hyprctl reload
