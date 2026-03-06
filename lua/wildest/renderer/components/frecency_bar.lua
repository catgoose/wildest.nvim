---@mod wildest.renderer.components.frecency_bar Frecency Heatmap Component
---@brief [[
---Frecency heatmap component for popupmenu renderers.
---Shows a colored indicator next to each candidate based on usage frequency.
---Hot (frequently used) items glow warm, cold items are dim.
---Theme-aware: derives gradient from the active colorscheme when possible.
---@brief ]]

local BaseComponent = require("wildest.renderer.components.base")
local M = {}

--- Fallback gradient: grey → green (more matches = greener)
local fallback_gradient = {
  { name = "WildestHeatCold", fg = "#555555" },
  { name = "WildestHeatCool", fg = "#667744" },
  { name = "WildestHeatWarm", fg = "#88994a" },
  { name = "WildestHeatMed", fg = "#77bb33" },
  { name = "WildestHeatHot", fg = "#55cc22" },
  { name = "WildestHeatFire", fg = "#33ff00" },
}

--- Blend two hex colors
---@param c1 string hex like '#rrggbb'
---@param c2 string hex like '#rrggbb'
---@param t number 0.0 = all c1, 1.0 = all c2
---@return string hex
local function blend(c1, c2, t)
  local r1, g1, b1 =
    tonumber(c1:sub(2, 3), 16), tonumber(c1:sub(4, 5), 16), tonumber(c1:sub(6, 7), 16)
  local r2, g2, b2 =
    tonumber(c2:sub(2, 3), 16), tonumber(c2:sub(4, 5), 16), tonumber(c2:sub(6, 7), 16)
  local r = math.floor(r1 + (r2 - r1) * t)
  local g = math.floor(g1 + (g2 - g1) * t)
  local b = math.floor(b1 + (b2 - b1) * t)
  return string.format("#%02x%02x%02x", r, g, b)
end

--- Try to derive a theme-aware gradient from the active colorscheme.
--- Uses Comment fg as cold and DiagnosticOk/String fg as hot (green = more matches).
---@return string[]|nil gradient hex colors (cold→hot), or nil if detection fails
local function derive_gradient_from_theme()
  local function get_fg(name)
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
    if ok and hl and hl.fg then
      return string.format("#%06x", hl.fg)
    end
    return nil
  end

  local cold = get_fg("Comment") or get_fg("NonText")
  local hot = get_fg("DiagnosticOk") or get_fg("String") or get_fg("DiagnosticHint")
  local mid = get_fg("DiagnosticWarn") or get_fg("Type")

  if not cold or not hot then
    return nil
  end

  -- Build a 6-step gradient: cold → mid → hot (green)
  mid = mid or blend(cold, hot, 0.5)
  return {
    cold,
    blend(cold, mid, 0.5),
    mid,
    blend(mid, hot, 0.4),
    blend(mid, hot, 0.7),
    hot,
  }
end

--- Ensure highlight groups exist for a list of named entries (fallback gradient).
---@return string[] hl_groups
local function ensure_fallback_hl_groups()
  local groups = {}
  for i, entry in ipairs(fallback_gradient) do
    vim.api.nvim_set_hl(0, entry.name, { fg = entry.fg, default = true })
    groups[i] = entry.name
  end
  return groups
end

--- Build theme-aware gradient highlight groups.
--- Tries to derive colors from the active colorscheme first, falls back to defaults.
---@return string[] hl_groups
local function ensure_default_hl_groups()
  local colors = derive_gradient_from_theme()
  if colors then
    local groups = {}
    for i, color in ipairs(colors) do
      local name = fallback_gradient[i] and fallback_gradient[i].name or ("WildestHeat" .. i)
      vim.api.nvim_set_hl(0, name, { fg = color, default = true })
      groups[i] = name
    end
    return groups
  end
  return ensure_fallback_hl_groups()
end

--- Create highlight groups from hex color strings.
---@param colors string[] hex fg colors
---@param prefix string hl group name prefix
---@return string[] hl_groups
local function ensure_hl_groups(colors, prefix)
  local groups = {}
  for i, color in ipairs(colors) do
    local name = prefix .. i
    vim.api.nvim_set_hl(0, name, { fg = color, default = true })
    groups[i] = name
  end
  return groups
end

--- Create a frecency heatmap bar component.
--- Shows a colored character next to each candidate. The color is chosen from
--- a gradient based on the candidate's frecency score relative to the page.
---
---@param opts? table
---   - colors?: string[] Hex fg colors for the gradient (cold → hot). Default: grey → orange → red.
---   - gradient?: string[] Pre-created hl group names (overrides colors).
---   - char?: string Indicator character (default "▎").
---   - dim_char?: string Character for zero-score items (default "▎"). Set to " " to hide zero-score items.
---   - weights?: table Custom frecency time bucket weights.
---@return table component
function M.new(opts)
  opts = opts or {}
  local char = opts.char or "▎"
  local dim_char = opts.dim_char or "▎"
  local weights = opts.weights
  local gradient = opts.gradient

  if not gradient then
    if opts.colors then
      gradient = ensure_hl_groups(opts.colors, "WildestHeat")
    else
      gradient = ensure_default_hl_groups()
    end
  end

  local component = setmetatable({}, { __index = BaseComponent })

  -- Cache frecency data per render cycle to avoid repeated disk reads.
  -- Keyed by run_id so it refreshes each pipeline run.
  local cached_data = nil
  local cached_run_id = -1
  -- Cache page-level max score for normalization
  local cached_max = nil
  local cached_page_key = nil

  function component:render(ctx)
    local candidate = ctx.candidate or ""
    if candidate == "" then
      return { { dim_char, gradient[1] } }
    end

    -- Load frecency data (once per run)
    local run_id = ctx.run_id
    if run_id ~= cached_run_id then
      cached_run_id = run_id
      cached_data = require("wildest.frecency").load()
      cached_max = nil
      cached_page_key = nil
    end

    local frecency = require("wildest.frecency")

    -- Compute max score across the visible page (once per page)
    local page_key = tostring(ctx.page_start or 0) .. ":" .. tostring(ctx.page_end or 0)
    if page_key ~= cached_page_key then
      cached_page_key = page_key
      cached_max = 0
      local start_idx = (ctx.page_start or 0) + 1
      local end_idx = (ctx.page_end or (ctx.total - 1)) + 1
      local candidates = ctx.result and ctx.result.value or {}
      for i = start_idx, math.min(end_idx, #candidates) do
        local c = candidates[i]
        local item = type(c) == "string" and c or (c.word or c[1] or tostring(c))
        local s = frecency.score(item, cached_data, weights)
        if s > cached_max then
          cached_max = s
        end
      end
    end

    -- Score this candidate
    local score = frecency.score(candidate, cached_data, weights)

    if score == 0 then
      return { { dim_char, gradient[1] } }
    end

    -- Normalize to gradient position
    local ratio = cached_max > 0 and (score / cached_max) or 0
    local idx = math.max(1, math.min(#gradient, math.ceil(ratio * #gradient)))

    return { { char, gradient[idx] } }
  end

  return component
end

return M
