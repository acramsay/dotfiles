local wezterm = require 'wezterm'

local module = {}

local pop = {
  key = 'b',
  action = wezterm.action.PopKeyTable
}

local panes_table = {
  pop,
  {
    key = 'x',
    action = wezterm.action.CloseCurrentPane { confirm = false },
  },
  {
    key = 's',
    action = wezterm.action.SplitPane { direction = 'Right' },
  },
  {
    key = 's',
    mods = 'SHIFT',
    action = wezterm.action.SplitPane { direction = 'Left' },
  },
  {
    key = 'v',
    action = wezterm.action.SplitPane { direction = 'Down' },
  },
  {
    key = 'v',
    mods = 'SHIFT',
    action = wezterm.action.SplitPane { direction = 'Up' },
  },
}

local tabs_table = {
  pop,
}

local keys_normal = {
  -- Navigation
  {
    key = 'h',
    mods = 'OPT|SHIFT',
    action = wezterm.action.ActivateTabRelative(-1),
  },
  {
    key = 'l',
    mods = 'OPT|SHIFT',
    action = wezterm.action.ActivateTabRelative(1),
  },
  {
    key = 'h',
    mods = 'OPT',
    action = wezterm.action.ActivatePaneDirection("Left"),
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
    action = wezterm.action.ActivatePaneDirection("Right"),
  },

  -- Key Tables
  {
    key = 'p',
    mods = 'OPT',
    action = wezterm.action.ActivateKeyTable {
      name = 'panes',
      -- one_shot = false,
    },
  },
}

function module.key_tables()
  return {
    panes = panes_table,
    tabs = tabs_table,
  }
end

function module.keys()
  return keys_normal
end

-- This doesn't seem to work. Disabling for now
-- config.mouse_bindings = {
--   {
--     event = { Up = { streak = 1, button = 'Left' } },
--     mods = 'OPT',
--     action = wezterm.action.OpenLinkAtMouseCursor,
--   },
-- }

return module
