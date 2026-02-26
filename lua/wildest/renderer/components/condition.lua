---@mod wildest.renderer.components.condition Conditional Component Wrapper
---@brief [[
---Conditional component wrapper.
---@brief ]]

local M = {}

--- Create a conditional component
---@param predicate fun(ctx: table): boolean
---@param if_true table|string component to render when true
---@param if_false? table|string component to render when false
---@return table component
function M.new(predicate, if_true, if_false)
  local component = {}

  function component:render(ctx)
    local target
    if predicate(ctx) then
      target = if_true
    else
      target = if_false
    end

    if target == nil then
      return {}
    end

    if type(target) == "string" then
      return { { target, "" } }
    end

    if type(target) == "table" and target.render then
      return target:render(ctx)
    end

    return {}
  end

  return component
end

return M
