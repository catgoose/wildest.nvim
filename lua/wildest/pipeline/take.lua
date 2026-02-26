---@mod wildest.pipeline.take Limit Results
---@brief [[
---Limit results pipeline step.
---@brief ]]

local M = {}

--- Limit the number of candidates
---@param n integer maximum number of results to keep
---@return fun(ctx: table, candidates: string[]): string[]
function M.take(n)
  return function(_ctx, candidates)
    if type(candidates) ~= "table" then
      return candidates
    end
    if #candidates <= n then
      return candidates
    end
    local result = {}
    for i = 1, n do
      result[i] = candidates[i]
    end
    return result
  end
end

return M
