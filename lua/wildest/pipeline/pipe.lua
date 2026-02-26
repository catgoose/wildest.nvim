---@mod wildest.pipeline.pipe Pipeline Composition
---@brief [[
---Compose sync pipeline steps.
---@brief ]]

local M = {}

--- Compose multiple pipeline steps into a single step
--- Each function receives (ctx, value) and returns a new value.
--- Unlike a pipeline array, this runs them as a single synchronous step.
---@param ... fun(ctx: table, x: any): any
---@return fun(ctx: table, x: any): any
function M.pipe(...)
  local fns = { ... }
  return function(ctx, x)
    local value = x
    for _, fn in ipairs(fns) do
      value = fn(ctx, value)
      if value == false then
        return false
      end
    end
    return value
  end
end

return M
