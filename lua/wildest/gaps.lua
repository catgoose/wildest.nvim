---@mod wildest.gaps Screen Gaps
---@brief [[
---Gutter and gap system for wildest.nvim floating windows.
---
---`gutter` adds margins between the screen edges and any floating windows.
---`gap` adds spacing between adjacent floating windows (menu ↔ preview).
---@brief ]]

local M = {}

---@class wildest.GapsResolved
---@field gutter {top: integer, right: integer, bottom: integer, left: integer}
---@field gap integer

---@type wildest.GapsResolved
local state = {
  gutter = { top = 0, right = 0, bottom = 0, left = 0 },
  gap = 0,
}

--- Normalize a gutter value into a 4-edge table.
---@param raw integer|table|nil
---@return {top: integer, right: integer, bottom: integer, left: integer}
local function normalize_edges(raw)
  if type(raw) == "number" then
    local g = math.max(0, raw)
    return { top = g, right = g, bottom = g, left = g }
  end
  if type(raw) == "table" then
    return {
      top = math.max(0, raw.top or 0),
      right = math.max(0, raw.right or 0),
      bottom = math.max(0, raw.bottom or 0),
      left = math.max(0, raw.left or 0),
    }
  end
  return { top = 0, right = 0, bottom = 0, left = 0 }
end

--- Configure from top-level config values.
---@param gutter_raw integer|table|nil  Number for uniform, or per-edge table
---@param gap_raw integer|nil  Number for between-window spacing
function M.setup(gutter_raw, gap_raw)
  state.gutter = normalize_edges(gutter_raw)
  state.gap = math.max(0, type(gap_raw) == "number" and gap_raw or 0)
end

--- Get gutter (screen-edge) margins.
---@return {top: integer, right: integer, bottom: integer, left: integer}
function M.gutter()
  return state.gutter
end

--- Get gap (between-window) spacing.
---@return integer
function M.gap()
  return state.gap
end

--- Expose normalize_edges for testing.
M._normalize_edges = normalize_edges

return M
