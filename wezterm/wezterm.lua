local wezterm = require("wezterm")
local config = wezterm.config_builder()

config.default_cursor_style = "SteadyBlock"
-- config.cursor_blink_rate = 0
-- config.debug_key_events = true

config.audible_bell = "Disabled"
config.default_prog = { "pwsh" }
config.initial_cols = 120
config.initial_rows = 30

-- Note that enabling this will break ahk remapping
config.enable_kitty_keyboard = true

config.enable_kitty_graphics = true
config.max_fps = 144

require("appearance").apply_to_config(config)
require("tab_title").apply_to_config(config)
require("tabs").apply_to_config(config)
require("nvim.passthrough-keys").apply_to_config(config)

return config
