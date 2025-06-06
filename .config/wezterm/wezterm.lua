local wezterm = require 'wezterm'
local keybinds = require 'keybinds'
local config = wezterm.config_builder()

-- window:effective_config()
-- config.color_scheme = 'Catppuccin Macchiato'
local transparency = wezterm.color.get_builtin_schemes()['Catppuccin Macchiato']
-- transparency.foreground = transparency.brights[3]
-- transparency.foreground = '#C4FFDB'

config.color_schemes = { ['Transparency'] = transparency }
config.color_scheme = 'Transparency'

-- config.font = wezterm.font("Rec Mono Casual", {weight="Regular", stretch="Normal", style="Normal"})
config.font = wezterm.font("Rec Mono Casual", { weight = "Regular", stretch = "Normal", style = "Italic" })
config.font_size = 14
config.line_height = 1.2

config.window_background_image = os.getenv('HOME') .. '/fire.jpg'
config.window_background_image_hsb = {
  brightness = 0.2,
}

config.key_tables = keybinds.key_tables()
config.keys = keybinds.keys()

-- Tab/Status Bar
config.tab_bar_at_bottom = true
config.window_frame = {
  font = config.font
}
wezterm.on(
  'update-status',
  function(window, pane)
    local cells = {}

    table.insert(cells, { Background = { Color = window:effective_config().window_frame.inactive_titlebar_bg } })

    local function add(text)
      table.insert(cells, { Text = ' ' .. text .. ' ' })
    end

    local cwd_uri = pane:get_current_working_dir()
    if cwd_uri then
      add(cwd_uri.file_path)
    end

    local process_name = pane:get_foreground_process_name()
    if process_name then
      add(Basename(process_name))
    end

    if #cells > 1 then
      window:set_right_status(wezterm.format(cells))
    end
  end
)

function Basename(s)
  return string.gsub(s, '(.*[/\\])(.*)', '%2')
end

return config
