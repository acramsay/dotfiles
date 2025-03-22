local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.color_scheme = 'Catppuccin Macchiato'
-- config.font = wezterm.font("Comic Code", {weight="Bold"})

-- config.font = wezterm.font("Comic Code", {weight="Regular", stretch="Normal", style="Normal"})

-- config.font = wezterm.font("Comic Mono", {weight="Regular", stretch="Normal", style="Normal"})
-- config.font = wezterm.font("Comic Neue", {weight="Regular", stretch="Normal", style="Normal"})
-- config.font = wezterm.font("Comic Relief", {weight="Regular", stretch="Normal", style="Normal"})
-- config.font = wezterm.font("Comic Relief", {weight="Regular", stretch="Normal", style="Normal"})
config.font = wezterm.font("ComicShannsMono Nerd Font Mono", {weight="Regular", stretch="Normal", style="Normal"})

return config
