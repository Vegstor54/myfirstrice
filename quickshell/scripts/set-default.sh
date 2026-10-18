#!/bin/bash
category=$1
app=$2
config="$HOME/.config/hypr/conf/programs.lua"
apps_dir="$HOME/.local/share/applications"
editor_desktop="default-editor.desktop"

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

sed -i "s|^local $var_name[[:space:]]*=.*|local $var_name = \"$app\"|" "$config"

# Ярлык редактора зависит и от редактора, и от терминала
case $category in
    editor|terminal) sync_editor_assoc ;;
esac

hyprctl reload
