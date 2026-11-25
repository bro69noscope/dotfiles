-- Make all panes in the row of the active pane the same width.
local wezterm = require("wezterm")
local act = wezterm.action

return wezterm.action_callback(function(window, pane)
  local tab = window:active_tab()

  local function geometry()
    local by_id = {}
    for _, p in ipairs(tab:panes_with_info()) do
      if p.is_zoomed then
        return nil
      end
      by_id[p.pane:pane_id()] = p
    end
    return by_id
  end

  local start = geometry()
  if not start then
    return
  end

  -- Panes that cross the top line of the active pane, from left to right
  local row_top = start[pane:pane_id()].top
  local row = {}
  for _, p in pairs(start) do
    if p.top <= row_top and row_top < p.top + p.height then
      table.insert(row, p)
    end
  end
  table.sort(row, function(a, b)
    return a.left < b.left
  end)

  local n = #row
  if n < 2 then
    return
  end

  -- Divider k is the column at the right of pane k (left + width). Dividers are 1 column wide.
  local cells = row[n].left + row[n].width - row[1].left - (n - 1)
  local base, extra = cells // n, cells % n
  local ids, targets = {}, {}
  local x = row[1].left
  for k = 1, n do
    ids[k] = row[k].pane:pane_id()
    x = x + base + (k <= extra and 1 or 0)
    targets[k] = x
    x = x + 1
  end

  local function divider(geo, k)
    return geo[ids[k]].left + geo[ids[k]].width
  end

  local function same(a, b)
    for id, p in pairs(a) do
      if p.left ~= b[id].left or p.width ~= b[id].width then
        return false
      end
    end
    return true
  end

  -- Move divider k by delta with the pane ids[j] active. Undo the move if divider k did not move.
  local function try_move(k, j, delta)
    local p = start[ids[j]].pane
    local before = geometry()
    p:activate()
    window:perform_action(
      act.AdjustPaneSize({ delta > 0 and "Right" or "Left", math.abs(delta) }),
      p
    )
    local after = geometry()
    if divider(after, k) ~= divider(before, k) then
      return true
    end
    if not same(before, after) then
      window:perform_action(
        act.AdjustPaneSize({ delta > 0 and "Left" or "Right", math.abs(delta) }),
        p
      )
    end
    return false
  end

  -- A move can shift other dividers in nested splits. Thus, do more than one pass.
  for _ = 1, 3 do
    local done = true
    for k = 1, n - 1 do
      local delta = targets[k] - divider(geometry(), k)
      if delta ~= 0 then
        done = false
        if not try_move(k, k, delta) then
          try_move(k, k + 1, delta)
        end
      end
    end
    if done then
      break
    end
  end

  pane:activate()
end)
