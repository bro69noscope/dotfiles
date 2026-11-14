local wezterm = require("wezterm")
local act = wezterm.action
local nvim = require("nvim")
local workspace_switcher =
  wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")

local M = {}

local function log_custom_info(window)
  local tab = window:active_tab()
  for _, pane in ipairs(tab:panes()) do
    local user_vars = pane:get_user_vars()
    local pane_id = pane:pane_id()
    wezterm.log_info("Pane " .. pane_id .. " user vars: " .. wezterm.json_encode(user_vars))
  end
end

function M.apply_to_config(config)
  config.key_tables = {
    copy_mode = wezterm.gui.default_key_tables().copy_mode,
    search_mode = wezterm.gui.default_key_tables().search_mode,
  }

  config.leader = { key = " ", mods = "SHIFT" }
  config.keys = {

    -- Toggle big margins for claude code usage
    {
      key = "|",
      mods = "CTRL|SHIFT",
      action = wezterm.action_callback(function(window, pane)
        local o = window:get_config_overrides() or {}
        if o.window_padding then
          o.window_padding = nil -- back to config default
        else
          o.window_padding = { left = 230, right = 230, top = 0, bottom = 0 }
        end
        window:set_config_overrides(o)
      end),
    },

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
    {
      key = "?",
      mods = "CTRL|SHIFT",
      action = wezterm.action_callback(function(window, pane)
        log_custom_info(window)
      end),
    },

    -- presentation zoom preset
    {
      key = "M",
      mods = "CTRL|SHIFT",
      action = wezterm.action_callback(function(win, pane)
        win:perform_action(wezterm.action.ResetFontSize, pane)
        for _ = 1, 4 do
          win:perform_action(wezterm.action.IncreaseFontSize, pane)
        end
      end),
    },

    -- Debug info
    {
      key = "i",
      mods = "CTRL|SHIFT",
      action = wezterm.action.ShowDebugOverlay,
    },

    -- HACK: Only enable multiline pasting while in Windows nvim or WSL to prevent accidents. (C-V is
    -- safe with pwsh right now and doesn't execute right away)
    -- NOTE: disabled for now, limitis usability in yazi etc.
    {
      key = "v",
      mods = "CTRL|SHIFT",
      action = wezterm.action_callback(function(window, pane)
        -- local vars = pane:get_user_vars() or {}
        -- local in_Windows_nvim = vars.in_Windows_nvim
        -- local in_wsl = vars.in_wsl
        -- if in_Windows_nvim == "1" or in_wsl == "1" then
        window:perform_action(wezterm.action.PasteFrom("Clipboard"), pane)
        -- end
      end),
    },

    -- alternative copy to clipboard
    {
      key = "Insert",
      mods = "CTRL",
      action = wezterm.action_callback(function(window, pane)
        local vars = pane:get_user_vars() or {}
        if vars.in_Windows_nvim == "1" then
          window:perform_action(wezterm.action.SendKey({ key = "Insert", mods = "CTRL" }), pane)
        else
          window:perform_action(wezterm.action.CopyTo("Clipboard"), pane)
        end
      end),
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
      action = nvim.passthrough("k", "CTRL|SHIFT", wezterm.action.ScrollByLine(-1)),
    },
    {
      key = "j",
      mods = "CTRL|SHIFT",
      action = nvim.passthrough("j", "CTRL|SHIFT", wezterm.action.ScrollByLine(1)),
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
      action = nvim.pane_nav("h", "Left"),
    },
    -- {
    --   key = "j",
    --   mods = "CTRL|SHIFT",
    --   action = wezterm.action.ActivatePaneDirection("Down"),
    -- },
    {
      key = "j",
      mods = "CTRL",
      action = nvim.pane_nav("j", "Down"),
    },
    -- {
    --   key = "k",
    --   mods = "CTRL|SHIFT",
    --   action = wezterm.action.ActivatePaneDirection("Up"),
    -- },
    {
      key = "k",
      mods = "CTRL",
      action = nvim.pane_nav("k", "Up"),
    },
    -- {
    --   key = "l",
    --   mods = "CTRL|SHIFT",
    --   action = wezterm.action.ActivatePaneDirection("Right"),
    -- },
    {
      key = "l",
      mods = "CTRL",
      action = nvim.pane_nav("l", "Right"),
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
    {
      key = "r",
      mods = "LEADER",
      action = act.PromptInputLine({
        description = "Enter new name for tab",
        action = wezterm.action_callback(function(window, pane, line)
          if line then
            local tab = window:active_tab()
            tab:set_title(line)
          end
        end),
      }),
    },

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
