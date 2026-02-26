---@mod wildest.filter.uniq Deduplication filter
---@brief [[
---Deduplication filter.
---@brief ]]

local M = {}

--- Create a dedup filter pipeline function
---@param opts? table { key?: fun(x):string }
---@return fun(ctx: table, candidates: string[]): string[]
function M.uniq_filter(opts)
  opts = opts or {}
  local key_fn = opts.key

  return function(_ctx, candidates)
    local seen = {}
    local result = {}
    for _, c in ipairs(candidates) do
      local key = key_fn and key_fn(c) or c
      if not seen[key] then
        seen[key] = true
        table.insert(result, c)
      end
    end
    return result
  end
end

return M
