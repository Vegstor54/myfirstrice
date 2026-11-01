#!/bin/bash
# Состояние kanshi для страницы «Дисплеи» (DisplaysTab.qml).
# Первая строка — running (запущен), stopped (установлен, но не запущен) или missing (не установлен).
# Вторая — имя профиля из ~/.config/kanshi/config (пустая, если профиля нет).

if ! command -v kanshi >/dev/null 2>&1; then
    echo missing
elif pgrep -x kanshi >/dev/null 2>&1; then
    echo running
else
    echo stopped
fi

# Профиль kanshi, как в конфиге: profile auto-custom { ... }
awk '/^profile /{ sub(/^profile /, ""); sub(/ *\{.*/, ""); print; exit }' \
    "$HOME/.config/kanshi/config" 2>/dev/null
