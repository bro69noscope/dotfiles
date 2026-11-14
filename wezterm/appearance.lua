local wezterm = require("wezterm")

local M = {}

-- 1080p 100% Win OS scale
-- local font_size = 11.8 -- Allows for 97/98 char length lines in Nvim vs 87/88 with 12.0.

-- 1440p 175% Win OS scale, 150 nvim columns. Dropoff to 141 at 12.5
-- local font_size = 12.4

-- 1080p 150% Win OS scale, 147 nvim columns.
local font_size = 11.2

function M.apply_to_config(config)
  config.font = wezterm.font("BerkeleyMono Nerd Font", { weight = "Regular" })
  config.font_size = font_size

  config.set_environment_variables = {
    WEZTERM_FONT_SIZE = tostring(font_size), -- Nvim dashboard integration usage
  }

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

  wezterm.on("format-window-title", function(tab, pane, tabs, panes, config)
    for _, t in ipairs(tabs) do
      local custom = t.active_pane.user_vars.USER_SET_WEZTERM_TITLE
      if custom and #custom > 0 then
        return custom
      end
    end
    return "Wezterm"
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
end

return M
