---@mod wildest.filter Fuzzy Filter
---@brief [[
---C FFI fuzzy matching filter for wildest.nvim.
---Uses a compiled C library (fuzzy.so) for high-performance fuzzy matching,
---scoring, filtering, and position extraction.
---@brief ]]

---@class wildest.FuzzyFilterOpts
---@field key? fun(candidate: any): string Key extraction function

local ffi = require("ffi")

local M = {}

ffi.cdef([[
bool fuzzy_has_match(const char *needle, const char *haystack);
double fuzzy_score(const char *needle, const char *haystack);
int fuzzy_filter_sort(
    const char *needle,
    const char **candidates, int num_candidates,
    int *out_indices, double *out_scores, int *out_count
);
int fuzzy_positions(
    const char *needle, const char *haystack,
    int *out_positions, int *out_count
);
]])

--- Load the C library
local function load_lib()
  local source = debug.getinfo(1, "S").source:sub(2)
  local dir = source:match("(.*/)")
  -- fuzzy.so is in the parent directory (lua/wildest/)
  local so_path = dir .. "../fuzzy.so"
  return ffi.load(so_path)
end

local ok, C = pcall(load_lib)
if not ok then
  vim.notify("[wildest] Failed to load fuzzy.so — run make in csrc/", vim.log.levels.ERROR)
  C = nil
end

--- Check if needle fuzzy-matches haystack
---@param needle string
---@param haystack string
---@return boolean
function M.has_match(needle, haystack)
  if not C then
    return false
  end
  return C.fuzzy_has_match(needle, haystack)
end

--- Score a single fuzzy match
---@param needle string
---@param haystack string
---@return number
function M.score(needle, haystack)
  if not C then
    return -1e9
  end
  return tonumber(C.fuzzy_score(needle, haystack)) or -1e9
end

--- Batch filter and sort candidates by fuzzy match score
--- This is the hot path — called on every keystroke
---@param needle string
---@param candidates string[]
---@return string[] filtered sorted candidates
---@return number[] scores
function M.filter_sort(needle, candidates)
  if not C then
    return {}, {}
  end

  local n = #candidates
  if n == 0 then
    return {}, {}
  end

  -- Create C string array
  local c_candidates = ffi.new("const char*[?]", n)
  -- Keep references to prevent GC
  local kept = {}
  for i = 1, n do
    local s = ffi.new("char[?]", #candidates[i] + 1)
    ffi.copy(s, candidates[i])
    c_candidates[i - 1] = s
    kept[i] = s
  end

  local out_indices = ffi.new("int[?]", n)
  local out_scores = ffi.new("double[?]", n)
  local out_count = ffi.new("int[1]")

  local ret = C.fuzzy_filter_sort(needle, c_candidates, n, out_indices, out_scores, out_count)
  if ret ~= 0 then
    vim.notify_once("[wildest] fuzzy_filter_sort failed (input may exceed limits)", vim.log.levels.WARN)
    return {}, {}
  end

  local count = out_count[0]
  local results = {}
  local scores = {}
  for i = 0, count - 1 do
    results[i + 1] = candidates[out_indices[i] + 1]
    scores[i + 1] = tonumber(out_scores[i])
  end

  return results, scores
end

--- Get matched character positions for highlighting
---@param needle string
---@param haystack string
---@return integer[]|nil positions (0-indexed byte positions)
function M.positions(needle, haystack)
  if not C then
    return nil
  end

  local max_n = 1024
  local out_positions = ffi.new("int[?]", max_n)
  local out_count = ffi.new("int[1]")

  local ret = C.fuzzy_positions(needle, haystack, out_positions, out_count)
  if ret ~= 0 then
    vim.notify_once("[wildest] fuzzy_positions failed (input may exceed limits)", vim.log.levels.WARN)
    return nil
  end

  local count = out_count[0]
  local positions = {}
  for i = 0, count - 1 do
    local pos = out_positions[i]
    if pos >= 0 then
      positions[#positions + 1] = pos
    end
  end

  return positions
end

--- Create a fuzzy filter pipeline function
---@param opts? table { key?: fun(x):string }
---@return fun(ctx: table, candidates: string[]): table
function M.fuzzy_filter(opts)
  opts = opts or {}
  local key_fn = opts.key

  return function(ctx, candidates)
    local input = ctx.input or ""
    if input == "" then
      return candidates
    end

    -- Extract the fuzzy query from input
    local query = input
    if ctx.arg then
      query = ctx.arg
    end

    if key_fn then
      -- Filter using key extraction
      local keys = {}
      for i, c in ipairs(candidates) do
        keys[i] = key_fn(c)
      end
      local filtered_keys, scores = M.filter_sort(query, keys)
      -- Map back to original candidates
      local result = {}
      -- Build key→index mapping
      local key_to_candidates = {}
      for i, k in ipairs(keys) do
        if not key_to_candidates[k] then
          key_to_candidates[k] = {}
        end
        table.insert(key_to_candidates[k], candidates[i])
      end
      for _, k in ipairs(filtered_keys) do
        local cs = key_to_candidates[k]
        if cs and #cs > 0 then
          table.insert(result, table.remove(cs, 1))
        end
      end
      return result
    else
      local filtered = M.filter_sort(query, candidates)
      return filtered
    end
  end
end

return M
