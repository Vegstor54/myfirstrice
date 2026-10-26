# VGST54OS-RICE
my first hyprland and quickshell rice

## Первый запуск

Цветовые файлы (`quickshell/Colors.qml`, `hypr/colors.lua`, `kitty/theme.conf`) создаёт matugen из обоев
и в git их нет. После установки конфигов один раз сгенерируйте их:

```bash
bash ~/.config/matugen/wallpaper-sync.sh /путь/к/обоям.png
```

Настройки бара и панели лежат в `quickshell/settings.json`, его создаёт сама оболочка при первом изменении.

Дальше тема меняется из панели (Style → Цветовая схема, Style → Обои).
Для Qt-приложений нужен `qt6ct`, для браузеров `xdg-desktop-portal-gtk`.
