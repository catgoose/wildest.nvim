---@mod wildest.pipeline.help_cache Help Tag Cache
---@brief [[
---Preloads and caches help tags for fast help completion.
---@brief ]]

local M = {}

local cached_tags = nil
local cache_timestamp = 0
local CACHE_TTL = 300 -- 5 minutes

--- Load all help tags synchronously.
---@return string[]
local function load_tags()
  local ok, tags = pcall(vim.fn.getcompletion, "", "help")
  if ok and tags then
    return tags
  end
  return {}
end

--- Get cached help tags, refreshing if stale.
---@return string[]
function M.get()
  local now = vim.uv.now() / 1000
  if cached_tags and (now - cache_timestamp) < CACHE_TTL then
    return cached_tags
  end

  cached_tags = load_tags()
  cache_timestamp = now
  return cached_tags
end

--- Filter cached tags by prefix.
---@param prefix string
---@return string[]
function M.filter(prefix)
  local all = M.get()
  if prefix == "" then
    return all
  end

  local lower_prefix = prefix:lower()
  local results = {}
  for _, tag in ipairs(all) do
    if tag:lower():find(lower_prefix, 1, true) then
      results[#results + 1] = tag
    end
  end
  return results
end

--- Invalidate the cache.
function M.clear()
  cached_tags = nil
  cache_timestamp = 0
end

--- Preload help tags (call from setup or first CmdlineEnter).
function M.preload()
  if cached_tags then
    return
  end
  -- Load synchronously — help tags are fast enough (~10ms)
  cached_tags = load_tags()
  cache_timestamp = vim.uv.now() / 1000
end

return M
