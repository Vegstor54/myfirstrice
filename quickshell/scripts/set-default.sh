#!/bin/bash
category=$1
app=$2
config="$HOME/.config/hypr/hyprland.lua"

[ -z "$app" ] && exit 1

case $category in
    terminal)    var_name="terminal" ;;
    filemanager) var_name="fileManager" ;;
    browser)     var_name="browser" ;;
    editor)      var_name="editor" ;;
    *) echo "Unknown category: $category"; exit 1 ;;
esac

sed -i "s|^local $var_name[[:space:]]*=.*|local $var_name = \"$app\"|" "$config"
hyprctl reload
