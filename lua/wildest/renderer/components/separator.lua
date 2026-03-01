---@mod wildest.renderer.components.separator Wildmenu Item Separator
---@brief [[
---Wildmenu item separator.
---@brief ]]

local BaseComponent = require("wildest.renderer.components.base")
local M = {}

--- Create a separator component for wildmenu
---@param opts? table { str?: string, hl?: string }
---@return table component
function M.new(opts)
  opts = opts or {}
  local str = opts.str or " | "
  local hl = opts.hl or "WildestSeparator"

  local component = setmetatable({}, { __index = BaseComponent })

  function component:render(_ctx)
    return { { str, hl } }
  end

  return component
end

return M
