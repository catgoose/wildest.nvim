---@mod wildest.pipeline.map Transform Mapping
---@brief [[
---Transform mapping pipeline step.
---@brief ]]

local M = {}

--- Transform each candidate through a function
--- The transform receives (candidate, index, ctx) and returns a new candidate.
--- If it returns nil, the candidate is dropped.
---@param transform fun(candidate: string, index: integer, ctx: table): string|nil
---@return fun(ctx: table, candidates: string[]): string[]
function M.map(transform)
  return function(ctx, candidates)
    if type(candidates) ~= "table" then
      return candidates
    end
    local result = {}
    for i, c in ipairs(candidates) do
      local mapped = transform(c, i, ctx)
      if mapped ~= nil then
        table.insert(result, mapped)
      end
    end
    return result
  end
end

return M
