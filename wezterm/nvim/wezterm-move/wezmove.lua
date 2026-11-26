local wezterm = require("wezterm")
local passthrough = require("nvim.passthrough-keys").passthrough

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

local function active_pane_is_zoomed(pane)
  for _, pane_info in ipairs(pane:tab():panes_with_info()) do
    if pane_info.is_active then
      return pane_info.is_zoomed
    end
  end
  return false
end

function M.pane_nav(key, direction)
  return passthrough(
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
