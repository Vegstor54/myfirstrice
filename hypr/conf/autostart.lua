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
     -- Генерируем цветовую схему из текущих обоев при старте
     hl.exec_cmd("sleep 1 && ~/.config/matugen/restore-wallpaper.sh")
--   hl.exec_cmd("nm-applet")
--   hl.exec_cmd("waybar & hyprpaper & firefox")
end)
