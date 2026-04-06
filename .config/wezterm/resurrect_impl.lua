local wezterm = require 'wezterm'
local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")

local module = {}

-- Helper to get state directory
local function get_state_dir()
  return resurrect.state_manager.save_state_dir .. "tab"
end

-- Save current tab layout
function module.save_tab_layout(window)
  local tab = window:active_tab()
  local current_title = tab:get_title()
  -- Check if a state file exists for the current title
  local default_name = current_title or ""
  window:perform_action(
    wezterm.action.PromptInputLine({
      description = "Enter name for saved tab layout:",
      initial_value = default_name,
      action = wezterm.action_callback(function(_, _, line)
        if line then
          local tab_state = resurrect.tab_state.get_tab_state(tab)
          resurrect.state_manager.save_state(tab_state, line)
          -- Always set the tab title to the saved name
          tab:set_title(line)
        end
      end),
    }),
    window:active_pane()
  )
end

-- Load tab layout into a new tab
function module.load_tab_layout(window)
  -- Get list of saved tab states
  local choices = {}
  local state_dir = get_state_dir()
  local files = wezterm.glob(state_dir .. "/*.json")
  for _, file in ipairs(files) do
    local name = file:match("([^/]+)%.json$")
    if name then
      table.insert(choices, { id = file, label = name })
    end
  end
  -- Show selector
  window:perform_action(
    wezterm.action.InputSelector({
      action = wezterm.action_callback(function(_, _, _, label)
        local state = resurrect.state_manager.load_state(label, "tab")
        if not state or next(state) == nil then
          window:toast_notification("WezTerm", "Failed to load state", nil, 2000)
          return
        end
        local tab, _, _ = window:mux_window():spawn_tab {}
        resurrect.tab_state.restore_tab(tab, state, {
          close_open_panes = true,
          relative = true,
          restore_text = false,
          on_pane_restore = resurrect.tab_state.default_on_pane_restore,
        })
        tab:set_title(label)
      end),
      title = "Load Tab State",
      description = "Select a saved tab layout to load into a new tab",
      choices = choices,
      fuzzy = true,
    }),
    window:active_pane()
  )
end

return module
