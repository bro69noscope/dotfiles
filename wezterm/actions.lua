-- Custom callback actions bound in keys.lua
local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

-- Toggle big margins for claude code usage
M.toggle_wide_margins = wezterm.action_callback(function(window, pane)
  local o = window:get_config_overrides() or {}
  if o.window_padding then
    o.window_padding = nil -- back to config default
  else
    o.window_padding = { left = 230, right = 230, top = 0, bottom = 0 }
  end
  window:set_config_overrides(o)
end)

-- for testing
M.log_user_vars = wezterm.action_callback(function(window, pane)
  local tab = window:active_tab()
  for _, p in ipairs(tab:panes()) do
    local user_vars = p:get_user_vars()
    local pane_id = p:pane_id()
    wezterm.log_info("Pane " .. pane_id .. " user vars: " .. wezterm.json_encode(user_vars))
  end
end)

-- presentation zoom preset
M.presentation_zoom = wezterm.action_callback(function(win, pane)
  win:perform_action(act.ResetFontSize, pane)
  for _ = 1, 4 do
    win:perform_action(act.IncreaseFontSize, pane)
  end
end)

-- HACK: Only enable multiline pasting while in Windows nvim or WSL to prevent accidents. (C-V is
-- safe with pwsh right now and doesn't execute right away)
-- NOTE: disabled for now, limitis usability in yazi etc.
M.paste = wezterm.action_callback(function(window, pane)
  -- local vars = pane:get_user_vars() or {}
  -- local in_Windows_nvim = vars.in_Windows_nvim
  -- local in_wsl = vars.in_wsl
  -- if in_Windows_nvim == "1" or in_wsl == "1" then
  window:perform_action(act.PasteFrom("Clipboard"), pane)
  -- end
end)

M.rename_tab = act.PromptInputLine({
  description = "Enter new name for tab",
  action = wezterm.action_callback(function(window, pane, line)
    if line then
      local tab = window:active_tab()
      tab:set_title(line)
    end
  end),
})

return M
