-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
--
hl.on("hyprland.start", function ()
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
