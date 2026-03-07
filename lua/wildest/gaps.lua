---@mod wildest.gaps Screen Gaps
---@brief [[
---i3-style gap system for wildest.nvim floating windows.
---
---`outer` adds margins between the screen edges and any floating windows.
---`inner` adds spacing between adjacent floating windows (menu ↔ preview).
---@brief ]]

local M = {}

---@class wildest.GapsConfig
---@field outer integer|{top: integer, right: integer, bottom: integer, left: integer}
---@field inner integer

---@class wildest.GapsResolved
---@field outer {top: integer, right: integer, bottom: integer, left: integer}
---@field inner integer

---@type wildest.GapsResolved
local state = {
  outer = { top = 0, right = 0, bottom = 0, left = 0 },
  inner = 0,
}

--- Normalize a gap value into a 4-edge table.
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

--- Configure gaps from the top-level config.
---@param raw integer|table|nil  Number for uniform gaps, or { outer?, inner? }
function M.setup(raw)
  if type(raw) == "number" then
    local g = math.max(0, raw)
    state.outer = { top = g, right = g, bottom = g, left = g }
    state.inner = g
  elseif type(raw) == "table" then
    state.outer = normalize_edges(raw.outer)
    state.inner = math.max(0, raw.inner or 0)
  else
    state.outer = { top = 0, right = 0, bottom = 0, left = 0 }
    state.inner = 0
  end
end

--- Get outer (screen-edge) gaps.
---@return {top: integer, right: integer, bottom: integer, left: integer}
function M.outer()
  return state.outer
end

--- Get inner (between-window) gap.
---@return integer
function M.inner()
  return state.inner
end

--- Expose normalize_edges for testing.
M._normalize_edges = normalize_edges

return M
