local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.color_scheme = 'Catppuccin Macchiato'

-- config.font = wezterm.font("Rec Mono Casual", {weight="Regular", stretch="Normal", style="Normal"})
config.font = wezterm.font("Rec Mono Casual", {weight="Regular", stretch="Normal", style="Italic"})
config.font_size = 14
config.line_height = 1.2

config.window_background_image = 'fire.jpg'
config.window_background_image_hsb = {
  brightness = 0.2,
}

-- Tab Bar
config.tab_bar_at_bottom = true
config.window_frame = {
  font = config.font
}
wezterm.on(
  'update-status',
  function(window, pane)
    content = basename(pane:get_foreground_process_name())
    content = content .. "  " .. pane:get_current_working_dir().path
    window:set_right_status(wezterm.format {
      { Text = content },
    })
  end
)

function basename(s)
  return string.gsub(s, '(.*[/\\])(.*)', '%2')
end

return config
