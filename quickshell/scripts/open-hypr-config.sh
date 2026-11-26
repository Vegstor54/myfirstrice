#!/bin/bash
# Открывает файл из конфигурации Hyprland в редакторе, выбранном в панели Defaults.

set -eu

relative_path=${1:-}
case "$relative_path" in
    ""|/*|*".."*) exit 1 ;;
esac

config_file="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/$relative_path"
[ -f "$config_file" ] || exit 1

scripts_dir=$(dirname "$0")
editor=$("$scripts_dir/get-default.sh" editor)
[ -n "$editor" ] || editor=nano

case "$editor" in
    emacs) exec emacs "$config_file" ;;
    *)     exec "$scripts_dir/run-in-terminal.sh" "$editor" "$config_file" ;;
esac
