-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
--
-- Основной монитор записывает панель в conf/monitors.lua (return { primary = "..." }).
-- Если файл вернул не таблицу (старая версия), курсор просто не переносится.
local monitors = require("conf.monitors")
local primary = type(monitors) == "table" and monitors.primary or nil

hl.on("hyprland.start", function ()
     -- При старте фокус и курсор на основном мониторе (задаётся в панели: Displays -> «Основной при старте»),
     -- иначе курсор появляется на первом по порядку мониторе
     if primary then
          hl.exec_cmd("hyprctl dispatch 'hl.dsp.focus({ monitor = \"" .. primary .. "\" })'")
     end
     hl.exec_cmd("awww-daemon")
     hl.exec_cmd("quickshell")
     -- История буфера обмена: cliphist сохраняет текст и картинки (меню: Super+V)
     hl.exec_cmd("wl-paste --type text --watch cliphist store")
     hl.exec_cmd("wl-paste --type image --watch cliphist store")
     -- Генерируем цветовую схему из текущих обоев при старте
     hl.exec_cmd("sleep 1 && ~/.config/matugen/restore-wallpaper.sh")
--   hl.exec_cmd("nm-applet")
--   hl.exec_cmd("waybar & hyprpaper & firefox")
end)
