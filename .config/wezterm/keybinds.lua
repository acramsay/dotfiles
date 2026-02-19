local wezterm = require 'wezterm'

local module = {}

wezterm.on('switch-to-left', function(window, pane)
  local tab = window:mux_window():active_tab()

  if tab:get_pane_direction 'Left' ~= nil then
    window:perform_action(wezterm.action.ActivatePaneDirection 'Left', pane)
  else
    window:perform_action(wezterm.action.ActivateTabRelative(-1), pane)
    local panes = window:mux_window():active_tab():panes()
    panes[#panes]:activate()
  end
end)

wezterm.on('switch-to-right', function(window, pane)
  local tab = window:mux_window():active_tab()

  if tab:get_pane_direction 'Right' ~= nil then
    window:perform_action(wezterm.action.ActivatePaneDirection 'Right', pane)
  else
    window:perform_action(wezterm.action.ActivateTabRelative(1), pane)
    window:mux_window():active_tab():panes()[1]:activate()
  end
end)

local keys_normal = {
  {
    key = 'x',
    mods = 'OPT',
    action = wezterm.action.CloseCurrentPane { confirm = false },
  },
  -- Creating Tabs/Panes
  {
    key = 'p',
    mods = 'OPT',
    action = wezterm.action.SplitPane { direction = 'Right' },
  },
  {
    key = 'p',
    mods = 'OPT|SHIFT',
    action = wezterm.action.SplitPane { direction = 'Down' },
  },
  {
    key = 'n',
    mods = 'OPT',
    action = wezterm.action.SpawnTab 'CurrentPaneDomain',
  },
  -- Navigation
  {
    key = 'h',
    mods = 'OPT',
    action = wezterm.action.EmitEvent 'switch-to-left',
  },
  {
    key = 'j',
    mods = 'OPT',
    action = wezterm.action.ActivatePaneDirection("Down"),
  },
  {
    key = 'k',
    mods = 'OPT',
    action = wezterm.action.ActivatePaneDirection("Up"),
  },
  {
    key = 'l',
    mods = 'OPT',
    action = wezterm.action.EmitEvent 'switch-to-right',
  },
  -- Scrolling Panes
  {
    key = 'h',
    mods = 'OPT|SHIFT',
    action = wezterm.action.ScrollToTop,
  },
  {
    key = 'j',
    mods = 'OPT|SHIFT',
    action = wezterm.action.ScrollByPage(0.3),
  },
  {
    key = 'k',
    mods = 'OPT|SHIFT',
    action = wezterm.action.ScrollByPage(-0.3),
  },
  {
    key = 'l',
    mods = 'OPT|SHIFT',
    action = wezterm.action.ScrollToBottom,
  },
  -- Other
  {
    key = 'b',
    mods = 'OPT|SHIFT',
    action = wezterm.action.EmitEvent 'toggle-background',
  },
}

function module.keys()
  return keys_normal
end

return module
