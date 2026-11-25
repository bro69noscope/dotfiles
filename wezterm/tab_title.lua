local wezterm = require("wezterm")

local M = {}

local process_icons = {
  -- Shells
  ["powershell"] = "\u{f0a0a} ", --
  ["pwsh"] = "\u{f0a0a} ", --
  ["cmd"] = "\u{ebc4} ", --
  ["bash"] = "\u{e795} ", --
  ["zsh"] = "\u{e795} ", --
  ["fish"] = "\u{e795} ", --
  ["nu"] = "\u{e795} ", --

  -- Programming languages and runtimes
  ["python"] = "\u{e606} ", --
  ["node"] = "\u{ed0d} ", --
  ["ruby"] = "\u{e791} ", --
  ["java"] = "\u{e738} ", --
  ["perl"] = "\u{e769} ", --
  ["php"] = "\u{e73d} ", --

  -- Text editors and IDEs
  ["nvim"] = "\u{e62b} ", --
  ["vim"] = "\u{e62b} ", --
  ["code"] = "\u{e70c} ", --
  ["emacs"] = "\u{e7b4} ", --

  -- Version control
  ["git"] = "\u{f02a2} ", --
  ["lazygit"] = "\u{f02a2} ", --

  -- System tools
  ["htop"] = "\u{f85a} ", --
  ["top"] = "\u{f85a} ", --
  ["ssh"] = "\u{f817} ", --
  ["docker"] = "\u{f308} ", --

  -- File operations
  ["ranger"] = "\u{f413} ", --
  ["fzf"] = "\u{f349} ", --

  -- Networking
  ["ping"] = "\u{fb27} ", --
  ["curl"] = "\u{f8c8} ", --

  -- Miscellaneous
  ["lua"] = "\u{e620} ", --
  ["terraform"] = "\u{e7b7} ", --

  -- Additional common tools
  ["npm"] = "\u{e71e} ", --
  ["yarn"] = "\u{e718} ", --
  ["cargo"] = "\u{e7a8} ", --
  ["rustc"] = "\u{e7a8} ", --
  ["go"] = "\u{e626} ", --
  ["dotnet"] = "\u{e77f} ", --

  -- Manual Additions
  ["lua-language-server"] = "\u{f08b1} ",
  ["oh-my-posh"] = "\u{f0a0a} ",
  ["starship"] = "\u{f427} ",
  ["wslhost"] = "\u{e712} ",
}

-- Updated function to get process name
local function get_process_name(process_name)
  -- Extract just the executable name without path or extension
  -- wezterm.log_info("process_name : " .. tostring(process_name))
  local name
  if process_name and process_name ~= "" then
    name = process_name:match("([^\\]+)%.?[^.]*$")
    name = name:gsub("%.exe$", "")
  else
    name = "nil"
  end

  return name:lower()
end

local function get_last_two_path_segments(tab)
  local cwd_url = tab.active_pane.current_working_dir
  -- wezterm.log_info("cwd_url : " .. tostring(cwd_url))
  if cwd_url then
    local path = cwd_url.path

    -- Extract last path segment (current directory)
    local current_dir = string.match(path, "([^/]+)$") or "err"

    -- Remove the last segment and extract the one before it (parent directory)
    local path_without_last = string.match(path, "^(.+)/[^/]+$") or "err"
    local parent_dir = string.match(path_without_last, "([^/]+)$") or "err"

    return parent_dir, current_dir
  else
    return "no_dir", "no_dir"
  end
end

function M.apply_to_config(config)
  config.use_fancy_tab_bar = false
  config.tab_max_width = 45
  -- config.default_cursor_style = "SteadyBar"

  wezterm.on("toggle-tabbar", function(window, _)
    local overrides = window:get_config_overrides() or {}
    if overrides.enable_tab_bar == false then
      wezterm.log_info("tab bar shown")
      overrides.enable_tab_bar = true
    else
      wezterm.log_info("tab bar hidden")
      overrides.enable_tab_bar = false
    end
    window:set_config_overrides(overrides)
  end)

  wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
    local process_name = get_process_name(tab.active_pane.foreground_process_name)
    local process_icon = process_icons[process_name] or ""
    local tab_number = tab.tab_index + 1
    local is_zoomed = tab.active_pane.is_zoomed
    local zoom_icon = is_zoomed and "\u{f531} " or ""
    local os_icon = ""
    if process_name == "wslhost" then
      os_icon = "🐧"
    else
      os_icon = "🪟 "
    end

    -- tab.tab_title stays "" until something sets it explicitly (rename binding, tab:set_title(),
    -- `wezterm cli set-tab-title`).
    local explicit_title = tab.tab_title and #tab.tab_title > 0
    if explicit_title then
      local title = tab.tab_title or ""
      title = string.format("%s%d: %s%s ", zoom_icon, tab_number, process_icon, title)
      return {
        { Text = " " .. title .. " " },
      }
    end

    local parent_folder, cwd = get_last_two_path_segments(tab)

    -- Check if the tab has a custom title set by Neovim set through OSC sequences (should have "[nvim]" in the title)
    local pane_title = tab.active_pane.title or ""
    if pane_title and (pane_title:match("\u{e6ae}eovim") or pane_title:match("\u{e6ae}")) then
      local title = string.format("%s%d: %s", zoom_icon, tab_number, tab.active_pane.title)
      return {
        { Text = " " .. title .. " " },
      }
    else
      local prefix =
        string.format("%s%d: %s%s%s: ", zoom_icon, tab_number, os_icon, process_icon, process_name)
      local title = prefix .. "../" .. parent_folder .. "/" .. cwd
      if wezterm.column_width(title) > max_width - 2 then
        title = prefix .. "../" .. cwd
      end
      return {
        { Text = " " .. title .. " " },
      }
    end
  end)
end

return M
