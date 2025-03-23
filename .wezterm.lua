local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.color_scheme = 'Catppuccin Macchiato'

config.font = wezterm.font("Rec Mono Casual", {weight="Regular", stretch="Normal", style="Normal"})
-- config.font = wezterm.font("Rec Mono Casual", {weight="Regular", stretch="Normal", style="Italic"})
config.font_size = 14
config.line_height = 1.2

config.window_background_image = 'fire.jpg'
config.window_background_image_hsb = {
  brightness = 0.2,
}

return config
