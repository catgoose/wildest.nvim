---@mod wildest.renderer.components.arrows Previous/Next Arrow Indicators
---@brief [[
---Previous/next arrow indicators.
---@brief ]]

local BaseComponent = require("wildest.renderer.components.base")
local util = require("wildest.util")
local M = {}

--- Create arrows component for wildmenu (previous/next indicators)
---@param opts? table { previous?: string, next?: string, hl?: string }
---@return table component
function M.new(opts)
  opts = opts or {}
  local prev_arrow = opts.previous or " < "
  local next_arrow = opts.next or " > "
  local hl = opts.hl or "WildestArrows"

  local component = setmetatable({}, { __index = BaseComponent })

  --- Render left arrow (previous indicator)
  function component:render_left(ctx)
    if ctx.page_start and ctx.page_start > 0 then
      return { { prev_arrow, hl } }
    end
    return { { string.rep(" ", util.strdisplaywidth(prev_arrow)), "" } }
  end

  --- Render right arrow (next indicator)
  function component:render_right(ctx)
    if ctx.page_end and ctx.total and ctx.page_end < ctx.total - 1 then
      return { { next_arrow, hl } }
    end
    return { { string.rep(" ", util.strdisplaywidth(next_arrow)), "" } }
  end

  return component
end

return M
