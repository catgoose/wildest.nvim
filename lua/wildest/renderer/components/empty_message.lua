---@mod wildest.renderer.components.empty_message Static Empty Message Component
---@brief [[
---Static empty message component.
---@brief ]]

local M = {}

--- Create an empty message component
---@param msg? string message to show when no results
---@param hl? string highlight group
---@return table component
function M.new(msg, hl)
  msg = msg or " No results "
  hl = hl or "WarningMsg"

  local component = {}

  function component:render(ctx)
    if ctx.total and ctx.total > 0 then
      return {}
    end
    return { { msg, hl } }
  end

  return component
end

return M
