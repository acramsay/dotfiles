local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.color_scheme = 'Catppuccin Macchiato'
-- config.font = wezterm.font("Comic Code", {weight="Bold"})

-- config.font = wezterm.font("Rec Mono Casual", {weight="Regular", stretch="Normal", style="Normal"})
config.font = wezterm.font("Rec Mono Casual", {weight="Regular", stretch="Normal", style="Italic"})
config.font_size = 14

return config
