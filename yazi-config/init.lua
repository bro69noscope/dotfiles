-- bookmarks
local bookmarks = {}

local path_sep = package.config:sub(1, 1)
local home_path = ya.target_family() == "windows" and os.getenv("USERPROFILE") or os.getenv("HOME")
if ya.target_family() == "windows" then
  table.insert(bookmarks, {
    tag = "Scoop Local",
    path = (os.getenv("SCOOP") or home_path .. "\\scoop") .. "\\",
    key = "p",
  })
  table.insert(bookmarks, {
    tag = "Scoop Global",
    path = (os.getenv("SCOOP_GLOBAL") or "C:\\ProgramData\\scoop") .. "\\",
    key = "P",
  })
end
table.insert(bookmarks, {
  tag = "Desktop",
  path = home_path .. path_sep .. "Desktop" .. path_sep,
  key = "d",
})

require("yamb"):setup({
  -- Optional, the path ending with path seperator represents folder.
  bookmarks = bookmarks,
  -- Optional, recieve notification everytime you jump.
  jump_notify = true,
  -- Optional, the cli of fzf.
  cli = "fzf",
  -- Optional, a string used for randomly generating keys, where the preceding characters have higher priority.
  keys = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",
  -- Optional, the path of bookmarks
  path = (ya.target_family() == "windows" and os.getenv("APPDATA") .. "\\yazi\\config\\bookmark")
    or (os.getenv("HOME") .. "/.config/yazi/bookmark"),
})

-- projects
local appdata = os.getenv("APPDATA")

require("projects"):setup({
  event = {
    save = {
      enable = true,
      name = "project-saved",
    },
    load = {
      enable = true,
      name = "project-loaded",
    },
    delete = {
      enable = true,
      name = "project-deleted",
    },
    delete_all = {
      enable = true,
      name = "project-deleted-all",
    },
    merge = {
      enable = true,
      name = "project-merged",
    },
  },
  save = {
    method = "lua", -- yazi | lua
    yazi_load_event = "@projects-load", -- event name when loading projects in `yazi` method
    lua_save_path = appdata .. "/yazi/state/projects.json",
    -- default value:
    -- windows: "%APPDATA%/yazi/state/projects.json"
    -- unix: "~/.local/state/yazi/projects.json"
  },
  last = {
    update_after_save = true,
    update_after_load = true,
    update_before_quit = false,
    load_after_start = false,
  },
  merge = {
    event = "projects-merge",
    quit_after_merge = false,
  },
  notify = {
    enable = true,
    title = "Projects",
    timeout = 3,
    level = "info",
  },
})
