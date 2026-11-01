------------------
---- MONITORS ----
------------------

-- Файл переписывает панель quickshell (Displays), руками можно править,
-- но панель при применении запишет его заново.
-- primary — монитор, на который при старте Hyprland ставятся фокус и курсор (см. autostart.lua).
-- See https://wiki.hypr.land/Configuring/Basics/Monitors/

hl.monitor({
    output   = "HDMI-A-1",
    mode     = "1680x1050@59.88",
    position = "0x0",
    scale    = 1,
})

hl.monitor({
    output   = "DP-3",
    mode     = "1920x1080@60",
    position = "1680x0",
    scale    = 1,
})

-- fallback для любых других мониторов
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

return { primary = "DP-3" }
