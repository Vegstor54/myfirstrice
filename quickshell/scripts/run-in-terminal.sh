#!/bin/bash
# Запускает команду в терминале по умолчанию (тот, что выбран во вкладке Defaults).
# Нужен лаунчеру для приложений с Terminal=true (htop, nvim и т.п.).
[ $# -eq 0 ] && exit 1

term=$("$(dirname "$0")/get-default.sh" terminal)
[ -z "$term" ] && term=kitty

case $term in
    wezterm) exec wezterm start -- "$@" ;;
    *)       exec "$term" -e "$@" ;;
esac
