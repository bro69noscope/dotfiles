local wezterm = require("wezterm")
local act = wezterm.action
local nvim_keys = require("nvim.passthrough-keys")
local wezmove = require("nvim.wezterm-move.wezmove")
local actions = require("actions.misc")
local equalize_pane_widths = require("actions.equalize_pane_widths")
local workspace_switcher =
  wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")

local M = {}

function M.apply_to_config(config)
  config.key_tables = {
    copy_mode = wezterm.gui.default_key_tables().copy_mode,
    search_mode = wezterm.gui.default_key_tables().search_mode,
  }

  config.leader = { key = " ", mods = "SHIFT" }
  config.keys = {

    -- Toggle big margins for claude code usage
    { key = "|", mods = "CTRL|SHIFT", action = actions.toggle_wide_margins },

    -- spawn tabs preset
    { key = "o", mods = "LEADER", action = act.EmitEvent("spawn-named-tabs") },

    -- workspace switching
    {
      key = "g",
      mods = "CTRL|SHIFT",
      action = workspace_switcher.switch_workspace(),
    },
    {
      key = "s",
      mods = "LEADER",
      action = workspace_switcher.switch_to_prev_workspace(),
    },

    -- for testing
    { key = "?", mods = "CTRL|SHIFT", action = actions.log_user_vars },

    -- presentation zoom preset
    { key = "M", mods = "CTRL|SHIFT", action = actions.presentation_zoom },

    -- Debug info
    {
      key = "i",
      mods = "CTRL|SHIFT",
      action = wezterm.action.ShowDebugOverlay,
    },

    -- paste (see actions.paste for the disabled nvim/WSL-only guard)
    { key = "v", mods = "CTRL|SHIFT", action = actions.paste },

    -- alternative copy to clipboard
    {
      key = "Insert",
      mods = "CTRL",
      action = nvim_keys.passthrough("Insert", "CTRL", wezterm.action.CopyTo("Clipboard")),
    },

    -- Emojis
    {
      key = "o",
      mods = "CTRL|SHIFT",
      action = wezterm.action.CharSelect({}),
    },

    -- Search
    {
      key = "f",
      mods = "CTRL|SHIFT",
      action = wezterm.action.Search({ CaseInSensitiveString = "" }),
    },

    -- Scrolling
    {
      key = "l",
      mods = "CTRL|SHIFT",
      action = wezterm.action.ScrollByPage(-1 / 2),
    },
    {
      key = "h",
      mods = "CTRL|SHIFT",
      action = wezterm.action.ScrollByPage(1 / 2),
    },

    {
      key = "k",
      mods = "CTRL|SHIFT",
      action = nvim_keys.ctrl_shift("k", wezterm.action.ScrollByLine(-1)),
    },
    {
      key = "j",
      mods = "CTRL|SHIFT",
      action = nvim_keys.ctrl_shift("j", wezterm.action.ScrollByLine(1)),
    },

    -- Explict passthroughs required for nvim to receive these key events as <C-S-key>
    {
      key = "s",
      mods = "CTRL|SHIFT",
      action = nvim_keys.ctrl_shift("s"),
    },

    -- Full screen
    { key = "F11", action = wezterm.action.ToggleFullScreen },

    -- Pick tab
    { key = "T", mods = "LEADER", action = wezterm.action.ShowTabNavigator },

    -- Navigate between panes
    -- {
    --   key = "h",
    --   mods = "CTRL|SHIFT",
    --   action = wezterm.action.ActivatePaneDirection("Left"),
    -- },
    {
      key = "h",
      mods = "CTRL",
      action = wezmove.pane_nav("h", "Left"),
    },
    -- {
    --   key = "j",
    --   mods = "CTRL|SHIFT",
    --   action = wezterm.action.ActivatePaneDirection("Down"),
    -- },
    {
      key = "j",
      mods = "CTRL",
      action = wezmove.pane_nav("j", "Down"),
    },
    -- {
    --   key = "k",
    --   mods = "CTRL|SHIFT",
    --   action = wezterm.action.ActivatePaneDirection("Up"),
    -- },
    {
      key = "k",
      mods = "CTRL",
      action = wezmove.pane_nav("k", "Up"),
    },
    -- {
    --   key = "l",
    --   mods = "CTRL|SHIFT",
    --   action = wezterm.action.ActivatePaneDirection("Right"),
    -- },
    {
      key = "l",
      mods = "CTRL",
      action = wezmove.pane_nav("l", "Right"),
    },

    -- Split panes
    {
      key = "H",
      mods = "LEADER",
      action = wezterm.action.SplitPane({
        direction = "Left",
        size = { Percent = 50 },
      }),
    },
    {
      key = "J",
      mods = "LEADER",
      action = wezterm.action.SplitPane({
        direction = "Down",
        size = { Percent = 50 },
      }),
    },
    {
      key = "K",
      mods = "LEADER",
      action = wezterm.action.SplitPane({
        direction = "Up",
        size = { Percent = 50 },
      }),
    },
    {
      key = "L",
      mods = "LEADER",
      action = wezterm.action.SplitPane({
        direction = "Right",
        size = { Percent = 50 },
      }),
    },

    -- Resize panes
    {
      key = "LeftArrow",
      mods = "CTRL|SHIFT",
      action = wezterm.action.AdjustPaneSize({ "Left", 3 }),
    },
    {
      key = "RightArrow",
      mods = "CTRL|SHIFT",
      action = wezterm.action.AdjustPaneSize({ "Right", 3 }),
    },
    {
      key = "UpArrow",
      mods = "CTRL|SHIFT",
      action = wezterm.action.AdjustPaneSize({ "Up", 3 }),
    },
    {
      key = "DownArrow",
      mods = "CTRL|SHIFT",
      action = wezterm.action.AdjustPaneSize({ "Down", 3 }),
    },
    { key = "=", mods = "LEADER", action = equalize_pane_widths },

    -- Close panes
    {
      key = "d",
      mods = "CTRL|SHIFT",
      action = wezterm.action.CloseCurrentPane({ confirm = true }),
    },
    {
      key = "X",
      mods = "LEADER",
      action = wezterm.action({ EmitEvent = "close_other_tabs" }),
    },

    -- Rename tab
    { key = "r", mods = "LEADER", action = actions.rename_tab },

    -- Custom bind for nvim
    {
      key = "Enter",
      mods = "ALT",
      action = "DisableDefaultAssignment",
    },
    -- Disable for Pwsh
    {
      key = "Tab",
      mods = "CTRL",
      action = "DisableDefaultAssignment",
    },
  }

  -- Add tab movement keybindings
  for i = 1, 8 do
    -- CTRL+ALT + number to move to that position
    table.insert(config.keys, {
      key = tostring(i),
      mods = "CTRL|ALT",
      action = wezterm.action.MoveTab(i - 1),
    })
  end
end

return M
