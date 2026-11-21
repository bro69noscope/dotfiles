-- Key passthrough helpers: send the key to nvim (or WSL) when it is in the pane, else run the
-- wezterm action.
local wezterm = require("wezterm")

local M = {}

local function write_zoom_info(zoomed)
  local temp_dir = os.getenv("TEMP") or os.getenv("TMPDIR") or "/tmp"
  local zoom_file = temp_dir .. "/wezterm_zoom.txt"
  local file = io.open(zoom_file, "w")
  if not file then
    wezterm.log_error("Failed to open zoom file for writing: " .. zoom_file)
    return
  end
  file:write(zoomed and "true" or "false")
  file:close()
end

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

local function active_pane_is_zoomed(pane)
  for _, pane_info in ipairs(pane:tab():panes_with_info()) do
    if pane_info.is_active then
      return pane_info.is_zoomed
    end
  end
  return false
end

function M.pane_nav(key, direction)
  return M.passthrough(
    key,
    "CTRL",
    wezterm.action.ActivatePaneDirection(direction),
    function(pane, vars)
      local zoomed = active_pane_is_zoomed(pane)
      write_zoom_info(zoomed)
      return vars.in_Windows_nvim == "1" or vars.in_wsl == "1" or zoomed
    end
  )
end

return M
