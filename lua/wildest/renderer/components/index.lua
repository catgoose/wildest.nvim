---@mod wildest.renderer.components.index Position Indicator Component
---@brief [[
---Position indicator component.
---@brief ]]

local BaseComponent = require("wildest.renderer.components.base")
local M = {}

--- Create an index component showing "X/Y"
---@param opts? table { hl?: string, format?: string }
---@return table component
function M.new(opts)
  opts = opts or {}
  local hl = opts.hl or "WildestIndex"
  local format = opts.format or " %d/%d "

  local component = setmetatable({}, { __index = BaseComponent })

  function component:render(ctx)
    local selected = (ctx.selected or -1) + 1
    local total = ctx.total or 0

    if selected <= 0 then
      selected = 0
    end

    local text = string.format(format, selected, total)
    return { { text, hl } }
  end

  return component
end

return M
