#!/bin/bash
# Возвращает JSON список установленных программ для категории

category=$1

case $category in
    terminal)
        apps="kitty alacritty foot wezterm"
        ;;
    filemanager)
        apps="nautilus dolphin thunar nemo"
        ;;
    browser)
        apps="firefox chromium qutebrowser brave-browser"
        ;;
    editor)
        apps="nvim vim nano emacs"
        ;;
    *)
        echo "[]"
        exit 0
        ;;
esac

installed=()
for app in $apps; do
    if which $app &>/dev/null; then
        installed+=("\"$app\"")
    fi
done

echo "[$(IFS=,; echo "${installed[*]}")]"
