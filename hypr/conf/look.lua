-- colors.lua генерирует matugen и в git его нет; пока он не создан (первая установка), берём запасные цвета
local ok, c = pcall(require, "colors")
if not ok then
    c = { primary = "rgba(b4c5ffee)", tertiary = "rgba(e2bbdbee)", inactive = "rgba(45464faa)" }
end

-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
    general = {
        gaps_in  = 3,
        gaps_out = 15,

        border_size = 2,

        col = {
            active_border   = { colors = { c.primary, c.tertiary }, angle = 45 },
            inactive_border = c.inactive,
        },

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = false,

        -- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 0,
        rounding_power = 0,

        -- Change transparency of focused and unfocused windows
        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a,
        },

        blur = {
            enabled   = true,
            size      = 3,
            passes    = 1,
            vibrancy  = 0.1696,
        },
    },

    -- Кривые и сами анимации лежат в animations.lua
    animations = {
        enabled = true,
    },
})


----------------
----  MISC  ----
----------------

hl.config({
    misc = {
        force_default_wallpaper = -1,    -- Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo   = true, -- If true disables the random hyprland logo / anime girl background. :(
        -- Окно, которое просит фокус (например, по клику на уведомление), получает его,
        -- а не просто подсвечивается как срочное
        focus_on_activate       = true,
    },
})
