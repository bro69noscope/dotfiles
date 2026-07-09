local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action
local manually_set_titles = {}
local font_size = 11.8 -- Allows for 97/98 char length lines in Nvim vs 87/88 with 12.0.
-- local font_size = 12
config.font = wezterm.font("BerkeleyMono Nerd Font", { weight = "Regular" })
config.font_size = font_size
config.default_cursor_style = "SteadyBlock"
-- config.cursor_blink_rate = 0
-- config.debug_key_events = true

config.set_environment_variables = {
  WEZTERM_FONT_SIZE = tostring(font_size), -- Nvim dashboard integration usage
}

config.audible_bell = "Disabled"
config.default_prog = { "pwsh" }
config.initial_cols = 120
config.initial_rows = 30
config.enable_kitty_keyboard = false -- Breaks ahk remapping
config.enable_kitty_graphics = true
if font_size ~= 12 then
  config.window_padding = { -- Adjust inevitable padding with font != 12
    left = 7,
    right = 0,
    top = 0,
    bottom = -20,
  }
else
  config.window_padding = {
    left = 0,
    right = 0,
    top = 0,
    bottom = 0,
  }
end
config.max_fps = 144

require("wezterm").on("format-window-title", function()
  return "Wezterm"
end)

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

wezterm.on("format-tab-title", function(tab, tabs, panes, hover, max_width)
  local process_name = get_process_name(tab.active_pane.foreground_process_name)
  local process_icon = process_icons[process_name] or ""
  local tab_number = tab.tab_index + 1
  local is_zoomed = tab.active_pane.is_zoomed
  local zoom_icon = is_zoomed and " " or ""
  local os_icon = ""
  if process_name == "wslhost" then
    os_icon = "🐧"
  else
    os_icon = "🪟 "
  end

  if manually_set_titles[tostring(tab.tab_id)] then -- Keep the title if it was manually set
    local title = tab.tab_title or ""

    return {
      { Text = string.format("%s%d: %s%s ", zoom_icon, tab_number, process_icon, title) },
    }
  end

  local parent_folder, cwd = get_last_two_path_segments(tab)

  -- Check if the tab has a custom title set by Neovim set through OSC sequences (should have "[nvim]" in the title)
  local pane_title = tab.active_pane.title or ""
  if pane_title and (pane_title:match("eovim") or pane_title:match("")) then
    local title = string.format("%s%d: %s", zoom_icon, tab_number, tab.active_pane.title)
    return {
      { Text = " " .. title .. " " },
    }
  else
    local title = string.format(
      "%s%d: %s%s%s: ../%s/%s",
      zoom_icon,
      tab_number,
      os_icon,
      process_icon,
      process_name,
      parent_folder,
      cwd
    )
    return {
      { Text = " " .. title .. " " },
    }
  end
end)

config.inactive_pane_hsb = {
  hue = 1.0,
  saturation = 0.7,
  brightness = 0.7,
}

local scheme_name = "tokyonight_storm"
local scheme = wezterm.get_builtin_color_schemes()[scheme_name]

-- scheme.brights[1] = "#ff69b4" -- set pwsh args comments to pink ! (brightblack)
scheme.brights[2] = "#fc5858" -- more saturated reds (brightred)
-- scheme.ansi[2] = "#fc6565" -- (red)
-- scheme.brights[3] = "#b4ed77" -- more saturated greens (brightgreen)
-- scheme.ansi[3] = "#b4ed77" -- (green)
-- scheme.brights[8] = "#67e6e6" -- (brightwhite)
-- scheme.ansi[8] = "#c2d0f2" -- (white)

config.colors = scheme

config.colors.tab_bar = {
  background = "#16161e", -- Darker background for the tab bar
  active_tab = {
    bg_color = "#1a1b26", -- Slightly lighter than the tab bar background
    fg_color = "#ff9e64", -- Orange pop color from Tokyo Night theme
    intensity = "Bold",
    italic = false,
  },
  inactive_tab = {
    bg_color = "#16161e", -- Same as tab bar background
    fg_color = "#4b94a6", -- Muted foreground
    italic = true,
  },
  inactive_tab_hover = {
    bg_color = "#1f2335", -- Slightly lighter on hover
    fg_color = "#73e3ff", -- Tokyo Night cyan
    italic = false,
  },
  new_tab = {
    bg_color = "#16161e", -- Same as tab bar background
    fg_color = "#545c7e", -- Same as inactive tab
    italic = false,
  },
  new_tab_hover = {
    bg_color = "#1f2335", -- Same as inactive tab hover
    fg_color = "#7dcfff", -- Same as inactive tab hover
    italic = false,
  },
}

config.background = {
  {
    source = {
      File = "C:/Users/ville/OneDrive/Pictures/background/luffy_sit.jpg",
    },
    hsb = {
      brightness = 0.02,
    },
  },
  {
    source = {
      Color = "rgba(28, 33, 39, 0.55)",
    },
    height = "100%",
    width = "100%",
  },
}

config.key_tables = {
  copy_mode = wezterm.gui.default_key_tables().copy_mode,
  search_mode = wezterm.gui.default_key_tables().search_mode,
}

local function get_uri(window, pane)
  local uri = pane:get_current_working_dir()
  if uri then
    wezterm.log_info(uri)
  end
end

local function log_custom_info(window)
  local tab = window:active_tab()
  for _, pane in ipairs(tab:panes()) do
    local user_vars = pane:get_user_vars()
    local pane_id = pane:pane_id()
    wezterm.log_info("Pane " .. pane_id .. " user vars: " .. wezterm.json_encode(user_vars))
  end
end

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

wezterm.on("close_other_tabs", function(window, pane)
  wezterm.log_info("=== close_other_tabs: start ===")
  local mux_window = window:mux_window()

  local function close_next()
    local current_tab_id = pane:tab():tab_id()
    local mux_tabs = mux_window:tabs()
    wezterm.log_info(
      tostring(#mux_tabs) .. " tab(s) open, current tab_id=" .. tostring(current_tab_id)
    )

    local target = nil
    for _, tab in ipairs(mux_tabs) do
      if tab:tab_id() ~= current_tab_id then
        target = tab
        break
      end
    end

    if not target then
      wezterm.log_info("=== close_other_tabs: done ===")
      return
    end

    target:activate()
    local pane_toclose = window:active_pane()
    wezterm.log_info(
      "closing pane " .. tostring(pane_toclose:pane_id()) .. " in tab " .. tostring(target:tab_id())
    )
    window:perform_action(act.CloseCurrentPane({ confirm = false }), pane_toclose)

    close_next()
  end

  close_next()
end)

config.leader = { key = " ", mods = "SHIFT" }
config.keys = {

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
    key = "/",
    mods = "CTRL",
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
  {
    key = "v",
    mods = "CTRL|SHIFT",
    action = wezterm.action_callback(function(window, pane)
      local vars = pane:get_user_vars() or {}
      local in_Windows_nvim = vars.in_Windows_nvim
      local in_wsl = vars.in_wsl
      if in_Windows_nvim == "1" or in_wsl == "1" then
        window:perform_action(wezterm.action.PasteFrom("Clipboard"), pane)
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
    action = wezterm.action.ScrollByLine(-1),
  },
  {
    key = "j",
    mods = "CTRL|SHIFT",
    action = wezterm.action.ScrollByLine(1),
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
    action = wezterm.action_callback(function(window, pane)
      local vars = pane:get_user_vars() or {}
      local in_Windows_nvim = vars.in_Windows_nvim
      local in_wsl = vars.in_wsl
      local tab = pane:tab()

      local panes_with_info = tab:panes_with_info()

      local pane_is_zoomed = false
      for _, pane_info in ipairs(panes_with_info) do
        if pane_info.is_active then
          pane_is_zoomed = pane_info.is_zoomed
          break
        end
      end

      write_zoom_info(pane_is_zoomed)

      if in_Windows_nvim == "1" or in_wsl == "1" or pane_is_zoomed then
        window:perform_action(wezterm.action.SendKey({ key = "h", mods = "CTRL" }), pane)
      else
        window:perform_action(wezterm.action.ActivatePaneDirection("Left"), pane)
      end
    end),
  },
  -- {
  --   key = "j",
  --   mods = "CTRL|SHIFT",
  --   action = wezterm.action.ActivatePaneDirection("Down"),
  -- },
  {
    key = "j",
    mods = "CTRL",
    action = wezterm.action_callback(function(window, pane)
      local vars = pane:get_user_vars() or {}
      local in_Windows_nvim = vars.in_Windows_nvim
      local in_wsl = vars.in_wsl
      local tab = pane:tab()

      local panes_with_info = tab:panes_with_info()

      local pane_is_zoomed = false
      for _, pane_info in ipairs(panes_with_info) do
        if pane_info.is_active then
          pane_is_zoomed = pane_info.is_zoomed
          break
        end
      end

      write_zoom_info(pane_is_zoomed)

      if in_Windows_nvim == "1" or in_wsl == "1" or pane_is_zoomed then
        window:perform_action(wezterm.action.SendKey({ key = "j", mods = "CTRL" }), pane)
      else
        window:perform_action(wezterm.action.ActivatePaneDirection("Down"), pane)
      end
    end),
  },
  -- {
  --   key = "k",
  --   mods = "CTRL|SHIFT",
  --   action = wezterm.action.ActivatePaneDirection("Up"),
  -- },
  {
    key = "k",
    mods = "CTRL",
    action = wezterm.action_callback(function(window, pane)
      local vars = pane:get_user_vars() or {}
      local in_Windows_nvim = vars.in_Windows_nvim
      local in_wsl = vars.in_wsl
      local tab = pane:tab()

      local panes_with_info = tab:panes_with_info()

      local pane_is_zoomed = false
      for _, pane_info in ipairs(panes_with_info) do
        if pane_info.is_active then
          pane_is_zoomed = pane_info.is_zoomed
          break
        end
      end

      write_zoom_info(pane_is_zoomed)

      if in_Windows_nvim == "1" or in_wsl == "1" or pane_is_zoomed then
        window:perform_action(wezterm.action.SendKey({ key = "k", mods = "CTRL" }), pane)
      else
        window:perform_action(wezterm.action.ActivatePaneDirection("Up"), pane)
      end
    end),
  },
  -- {
  --   key = "l",
  --   mods = "CTRL|SHIFT",
  --   action = wezterm.action.ActivatePaneDirection("Right"),
  -- },
  {
    key = "l",
    mods = "CTRL",
    action = wezterm.action_callback(function(window, pane)
      local vars = pane:get_user_vars() or {}
      local in_Windows_nvim = vars.in_Windows_nvim
      local in_wsl = vars.in_wsl
      local tab = pane:tab()

      local panes_with_info = tab:panes_with_info()

      local pane_is_zoomed = false
      for _, pane_info in ipairs(panes_with_info) do
        if pane_info.is_active then
          pane_is_zoomed = pane_info.is_zoomed
          break
        end
      end

      write_zoom_info(pane_is_zoomed)

      if in_Windows_nvim == "1" or in_wsl == "1" or pane_is_zoomed then
        window:perform_action(wezterm.action.SendKey({ key = "l", mods = "CTRL" }), pane)
      else
        window:perform_action(wezterm.action.ActivatePaneDirection("Right"), pane)
      end
    end),
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
    key = "x",
    mods = "LEADER",
    action = wezterm.action.CloseCurrentPane({ confirm = true }),
  },
  {
    key = "X",
    mods = "LEADER",
    action = wezterm.action({ EmitEvent = "close_other_tabs" }),
  },

  -- Zoom
  {
    key = "z",
    mods = "LEADER",
    action = wezterm.action.TogglePaneZoomState,
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
          manually_set_titles[tostring(tab:tab_id())] = true
          tab:set_title(line)
        end
      end),
    }),
  },

  -- New tab
  {
    key = "t",
    mods = "LEADER",
    action = wezterm.action({ SpawnTab = "CurrentPaneDomain" }),
  },

  -- {
  --   key = "T",
  --   mods = "LEADER",
  --   action = wezterm.action({ SpawnTab = "CurrentPaneDomain" }),
  -- },

  -- Switch tabs
  { key = "phys:1", mods = "LEADER", action = wezterm.action.ActivateTab(0) },
  { key = "phys:1", mods = "LEADER|SHIFT", action = wezterm.action.ActivateTab(0) },
  { key = "phys:2", mods = "LEADER", action = wezterm.action.ActivateTab(1) },
  { key = "phys:2", mods = "LEADER|SHIFT", action = wezterm.action.ActivateTab(1) },
  { key = "phys:3", mods = "LEADER", action = wezterm.action.ActivateTab(2) },
  { key = "phys:3", mods = "LEADER|SHIFT", action = wezterm.action.ActivateTab(2) },
  { key = "phys:4", mods = "LEADER", action = wezterm.action.ActivateTab(3) },
  { key = "phys:4", mods = "LEADER|SHIFT", action = wezterm.action.ActivateTab(3) },
  { key = "phys:5", mods = "LEADER", action = wezterm.action.ActivateTab(4) },
  { key = "phys:5", mods = "LEADER|SHIFT", action = wezterm.action.ActivateTab(4) },
  { key = "phys:6", mods = "LEADER", action = wezterm.action.ActivateTab(5) },
  { key = "phys:6", mods = "LEADER|SHIFT", action = wezterm.action.ActivateTab(5) },
  { key = "phys:7", mods = "LEADER", action = wezterm.action.ActivateTab(6) },
  { key = "phys:7", mods = "LEADER|SHIFT", action = wezterm.action.ActivateTab(6) },
  { key = "phys:8", mods = "LEADER", action = wezterm.action.ActivateTab(7) },
  { key = "phys:8", mods = "LEADER|SHIFT", action = wezterm.action.ActivateTab(7) },
  { key = "phys:9", mods = "LEADER", action = wezterm.action.ActivateTab(8) },
  { key = "phys:9", mods = "LEADER|SHIFT", action = wezterm.action.ActivateTab(8) },
  { key = "phys:0", mods = "LEADER", action = wezterm.action.ActivateTab(9) },
  { key = "phys:0", mods = "LEADER|SHIFT", action = wezterm.action.ActivateTab(9) },

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

return config
