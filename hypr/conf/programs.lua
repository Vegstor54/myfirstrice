---------------------
---- MY PROGRAMS ----
---------------------

-- Строки `local name = "value"` менять только в таком формате:
-- их читают и переписывают скрипты quickshell (get-default.sh / set-default.sh)
local terminal = "kitty"
local fileManager = "nautilus"
local menu = "hyprlauncher"
local browser = "firefox"
local editor = "nano"

return {
    terminal    = terminal,
    fileManager = fileManager,
    menu        = menu,
    browser     = browser,
    editor      = editor,
}
