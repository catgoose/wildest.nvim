---@mod wildest.pipeline.filter Predicate Filter
---@brief [[
---Predicate filter pipeline step.
---@brief ]]

local M = {}

--- Filter candidates with a predicate function
--- The predicate receives (candidate, index, ctx) and returns true to keep.
---@param predicate fun(candidate: string, index: integer, ctx: table): boolean
---@return fun(ctx: table, candidates: string[]): string[]
function M.filter(predicate)
  return function(ctx, candidates)
    if type(candidates) ~= "table" then
      return candidates
    end
    local result = {}
    for i, c in ipairs(candidates) do
      if predicate(c, i, ctx) then
        table.insert(result, c)
      end
    end
    return result
  end
end

return M
