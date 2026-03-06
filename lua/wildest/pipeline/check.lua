---@mod wildest.pipeline.check Predicate Gate
---@brief [[
---Predicate gate pipeline step.
---@brief ]]

local M = {}

--- Create a predicate gate pipeline function
--- If the predicate returns false, the pipeline fails (returns false).
---@param predicate fun(ctx: table, x: any): boolean
---@return wildest.PipelineStep
function M.check(predicate)
  return function(ctx, x)
    local passed = predicate(ctx, x) and true or false
    require("wildest.log").log("check", "eval", { input = ctx.input, passed = passed })
    if passed then
      return x
    end
    return false
  end
end

return M
