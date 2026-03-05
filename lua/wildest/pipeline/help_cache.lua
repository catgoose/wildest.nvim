---@mod wildest.pipeline.help_cache Help Tag Cache
---@brief [[
---Preloads and caches help tags for fast help completion.
---@brief ]]

local M = {}

local cached_tags = nil
local cache_timestamp = 0
local CACHE_TTL = 300 -- 5 minutes
local custom_command = nil -- user-provided command override

--- Load all help tags using Vim's built-in mechanism.
---@return string[]
local function load_tags_vim()
  local ok, tags = pcall(vim.fn.getcompletion, "", "help")
  if ok and tags then
    return tags
  end
  return {}
end

--- Load help tags using a custom command or function.
---@return string[]
local function load_tags_custom()
  local cmd = custom_command
  if type(cmd) == "function" then
    local ok, result = pcall(cmd)
    if ok and type(result) == "table" then
      return result
    end
    return load_tags_vim()
  end
  -- Run command synchronously — expects one tag per line
  local res = vim.system(cmd, { text = true }):wait()
  if res.code == 0 and res.stdout then
    return vim.split(res.stdout, "\n", { trimempty = true })
  end
  return load_tags_vim()
end

--- Load all help tags synchronously.
---@return string[]
local function load_tags()
  if custom_command then
    return load_tags_custom()
  end
  return load_tags_vim()
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

--- Configure the help cache with custom options.
---@param opts? table { command?: string[]|function, ttl?: integer }
function M.configure(opts)
  opts = opts or {}
  if opts.command ~= nil then
    custom_command = opts.command
  end
  if opts.ttl then
    CACHE_TTL = opts.ttl
  end
  cached_tags = nil
  cache_timestamp = 0
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
