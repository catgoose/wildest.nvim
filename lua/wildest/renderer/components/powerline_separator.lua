---@mod wildest.renderer.components.powerline_separator Powerline Separator Component
---@brief [[
---Powerline-style triangle separator component for wildmenu renderers.
---Renders a "" character with transition highlights derived from adjacent
---candidate background colors.
---@brief ]]

local BaseComponent = require("wildest.renderer.components.base")
local hl_mod = require("wildest.highlight")

local M = {}

--- Create a powerline separator component for the wildmenu
---@param opts? table { hl?: string, selected_hl?: string }
---@return table component
function M.new(opts)
  opts = opts or {}

  local component = setmetatable({}, { __index = BaseComponent })
  local hl_cache = {}

  --- Get or create a transition highlight (fg = left bg, bg = right bg)
  local function get_transition_hl(left_hl, right_hl)
    local key = left_hl .. ">" .. right_hl
    if hl_cache[key] then
      return hl_cache[key]
    end
    local left_def = vim.api.nvim_get_hl(0, { name = left_hl, link = false })
    local right_def = vim.api.nvim_get_hl(0, { name = right_hl, link = false })
    local fg = left_def.bg
    local bg = right_def.bg
    local name = string.format("WildestPowerline_%s_%s", left_hl, right_hl)
    hl_mod.make_hl(name, right_hl, { fg = fg, bg = bg })
    hl_cache[key] = name
    return name
  end

  function component:render(ctx)
    local default_hl = ctx.default_hl or opts.hl or "StatusLine"
    local selected_hl = ctx.selected_hl or opts.selected_hl or "WildMenu"

    local left_hl = ctx.is_left_selected and selected_hl or default_hl
    local right_hl = ctx.is_right_selected and selected_hl or default_hl

    local transition = get_transition_hl(left_hl, right_hl)
    return { { "\u{e0b0}", transition } }
  end

  return component
end

return M
