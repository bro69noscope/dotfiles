local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

local named_tabs_preset = {
  { cwd = "C:\\Users\\ville\\myfiles\\git-repos\\woertsposzibllen4me", title = "repo" },
  { cwd = "C:\\Users\\ville\\myfiles\\dotfiles\\nvim-config3.0", title = "nvimconfig" },
  {
    cwd = "C:\\Users\\ville\\myfiles\\streaming-programs\\streamerbot-portable-ftp\\Streamer.bot\\dlls",
    title = "logs",
  },
}

function M.apply_to_config(_)
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

  wezterm.on("spawn-named-tabs", function(window, pane)
    local mux_window = window:mux_window()
    local current_tab = pane:tab()
    for _, t in ipairs(named_tabs_preset) do
      local tab, new_pane, new_window = mux_window:spawn_tab({ cwd = t.cwd })
      tab:set_title(t.title)
    end
    current_tab:activate()
  end)
end

return M
