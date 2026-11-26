local wezterm = require("wezterm")

local M = {}

local function in_nvim(_, vars)
  return vars.in_Windows_nvim == "1"
end

function M.passthrough(key, mods, action, should_send)
  should_send = should_send or in_nvim
  return wezterm.action_callback(function(window, pane)
    local vars = pane:get_user_vars() or {}
    if should_send(pane, vars) then
      window:perform_action(wezterm.action.SendKey({ key = key, mods = mods }), pane)
    else
      window:perform_action(action, pane)
    end
  end)
end

-- Send ctrl+shift+<key> as a kitty CSI u sequence, so nvim receives <C-S-key> and not <C-key>.
-- Outside nvim, run the wezterm action (if any).
function M.ctrl_shift(key, action)
  return wezterm.action_callback(function(window, pane)
    local vars = pane:get_user_vars() or {}
    if in_nvim(pane, vars) then
      pane:send_text(string.format("\x1b[%d;6u", string.byte(key)))
    elseif action then
      window:perform_action(action, pane)
    end
  end)
end

return M
