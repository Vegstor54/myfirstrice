-- Главный файл конфига Hyprland: только подключает модули из conf/.
-- Docs: https://wiki.hypr.land/Configuring/Start/
--
-- colors.lua генерируется matugen (см. matugen/config.toml), руками не править.
-- Программы по умолчанию (conf/programs.lua) меняются из панели quickshell.

require("conf.env")
require("conf.monitors")
require("conf.programs")
require("conf.autostart")
require("conf.look")
require("conf.animations")
require("conf.layouts")
require("conf.input")
require("conf.binds")
require("conf.rules")
