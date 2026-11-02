# VGST54OS-RICE
my first hyprland and quickshell rice

## Установка (Arch Linux)

```bash
git clone https://github.com/Vegstor54/myfirstrice ~/myfirstrice
bash ~/myfirstrice/install.sh --wallpaper ~/Pictures/wall.png
```

Скрипт ставит пакеты из `packages/required.txt` (официальные репозитории через `pacman`, остальное из AUR через `yay` или `paru`),
делает ссылки `~/.config/{hypr,matugen,quickshell,kitty,qt6ct}` на репозиторий, включает `bluetooth.service` и по обоям создаёт первую палитру.
Уже существующие папки в `~/.config` не удаляются, а переезжают в `<имя>.bak-<дата>`. Повторный запуск безопасен.

Ключи: `--optional` (ещё `packages/optional.txt`), `--no-packages` (только ссылки), `--dry-run` (показать, что будет сделано), `--yes` (без вопросов).
Нужна версия Hyprland с конфигом на Lua. После установки выйдите из сессии и зайдите снова.

## Первый запуск

Цветовые файлы (`quickshell/Colors.qml`, `hypr/colors.lua`, `kitty/theme.conf`) создаёт matugen из обоев
и в git их нет. После установки конфигов один раз сгенерируйте их:

```bash
bash ~/.config/matugen/wallpaper-sync.sh /путь/к/обоям.png
```

Настройки бара и панели лежат в `quickshell/settings.json`, его создаёт сама оболочка при первом изменении.

Дальше тема меняется из панели (Style → Цветовая схема, Style → Обои).
Режимов темы три: «Из обоев» (палитра по обоям), «Тёмная» и «Светлая» (фиксированные, от обоев не зависят).
Для Qt-приложений нужен `qt6ct`, для браузеров `xdg-desktop-portal-gtk`.
Конфиг qt6ct лежит в `qt6ct/` (`~/.config/qt6ct` — симлинк на него), палитру `qt6ct/colors/matugen.conf` создаёт matugen.

## Структура quickshell/

| Папка | Что внутри |
|---|---|
| `shell.qml`, `Colors.qml`, `qmldir` | вход оболочки, палитра (её создаёт matugen), список типов |
| `state/` | синглтоны: настройки, состояние системы, трея и уведомлений |
| `bar/` | бар: модули, слоты, значки, столы, трек, cava (`cava.conf`) |
| `panel/` | панель SUPER+S и все её страницы настроек |
| `menus/` | меню под баром: значки, часы с плеером и календарём, буфер обмена |
| `tabs/` | вкладки Интернет, Bluetooth и Звук: их используют и меню значков, и Control Center |
| `notifications/` | всплывающие карточки, история и вкладка уведомлений |
| `scripts/` | вспомогательные shell-скрипты |

Новый тип добавляется строкой в `qmldir` (`Имя папка/Имя.qml`), а файл внутри папки подключает остальные типы через `import ".."`.

