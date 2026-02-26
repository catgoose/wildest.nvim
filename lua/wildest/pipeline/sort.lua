---@mod wildest.pipeline.sort Sorting Steps
---@brief [[
---Sorting pipeline steps.
---@brief ]]

local M = {}

--- Sort candidates with a comparator function
--- The comparator receives (a, b, ctx) and returns true if a should come first.
--- If no comparator is given, sorts lexically (A-Z).
---@param comparator? fun(a: string, b: string, ctx: table): boolean
---@return fun(ctx: table, candidates: string[]): string[]
function M.sort(comparator)
  return function(ctx, candidates)
    if type(candidates) ~= "table" then
      return candidates
    end
    local sorted = vim.list_extend({}, candidates)
    if comparator then
      table.sort(sorted, function(a, b)
        return comparator(a, b, ctx)
      end)
    else
      table.sort(sorted)
    end
    return sorted
  end
end

--- Sort candidates by a scoring function (descending — highest score first)
---@param scorer fun(candidate: string, ctx: table): number
---@return fun(ctx: table, candidates: string[]): string[]
function M.sort_by(scorer)
  return function(ctx, candidates)
    if type(candidates) ~= "table" then
      return candidates
    end
    -- Pre-compute scores
    local scored = {}
    for i, c in ipairs(candidates) do
      scored[i] = { candidate = c, score = scorer(c, ctx) }
    end
    table.sort(scored, function(a, b)
      return a.score > b.score
    end)
    local result = {}
    for i, s in ipairs(scored) do
      result[i] = s.candidate
    end
    return result
  end
end

return M
