---@mod wildest.shell.exec_cache Executable Cache
---@brief [[
---Caches $PATH executables for fast shell command completion.
---Scans $PATH directories asynchronously and caches the results.
---@brief ]]

local M = {}

local cached_executables = nil
local cache_timestamp = 0
local CACHE_TTL = 60 -- seconds before re-scanning

--- Scan $PATH synchronously and return a deduplicated, sorted list of executables.
---@return string[]
local function scan_path_sync()
  local path_str = vim.env.PATH or ""
  local sep = ":"
  local dirs = vim.split(path_str, sep, { trimempty = true })
  local seen = {}
  local results = {}

  for _, dir in ipairs(dirs) do
    local ok, entries = pcall(vim.fn.readdir, dir)
    if ok and entries then
      for _, name in ipairs(entries) do
        if not seen[name] then
          local full = dir .. "/" .. name
          -- Quick check: is it likely executable? Use luv for speed.
          local stat = vim.uv.fs_stat(full)
          if stat and stat.type == "file" and bit.band(stat.mode, 0x49) ~= 0 then
            seen[name] = true
            results[#results + 1] = name
          end
        end
      end
    end
  end

  table.sort(results)
  return results
end

--- Scan $PATH asynchronously using vim.system (compgen -c or similar).
---@param callback fun(executables: string[])
local function scan_path_async(callback)
  -- Use compgen for bash, or fall back to sync scan
  local shell = vim.env.SHELL or "/bin/sh"
  local is_bash = shell:find("bash") ~= nil

  if is_bash then
    vim.system({ "bash", "-c", "compgen -c" }, { text = true }, function(res)
      vim.schedule(function()
        if res.code == 0 and res.stdout then
          local lines = vim.split(res.stdout, "\n", { trimempty = true })
          local seen = {}
          local results = {}
          for _, name in ipairs(lines) do
            if not seen[name] then
              seen[name] = true
              results[#results + 1] = name
            end
          end
          table.sort(results)
          callback(results)
        else
          -- Fallback to sync scan
          callback(scan_path_sync())
        end
      end)
    end)
  else
    -- Non-bash: scan synchronously (still fast for most systems)
    vim.schedule(function()
      callback(scan_path_sync())
    end)
  end
end

--- Get cached executables, refreshing if stale.
--- On first call, does a sync scan. Triggers async refresh if cache is stale.
---@return string[]
function M.get()
  local now = vim.uv.now() / 1000 -- ms to seconds
  if cached_executables and (now - cache_timestamp) < CACHE_TTL then
    return cached_executables
  end

  if not cached_executables then
    -- First call: sync scan so we have results immediately
    cached_executables = scan_path_sync()
    cache_timestamp = now
    return cached_executables
  end

  -- Cache is stale — refresh async, return stale data for now
  scan_path_async(function(results)
    cached_executables = results
    cache_timestamp = vim.uv.now() / 1000
  end)

  return cached_executables
end

--- Filter cached executables by prefix.
---@param prefix string
---@return string[]
function M.filter(prefix)
  local all = M.get()
  if prefix == "" then
    return all
  end

  local lower_prefix = prefix:lower()
  local results = {}
  for _, name in ipairs(all) do
    if name:lower():sub(1, #prefix) == lower_prefix then
      results[#results + 1] = name
    end
  end
  return results
end

--- Invalidate the cache (e.g., after installing new programs).
function M.clear()
  cached_executables = nil
  cache_timestamp = 0
end

--- Preload the cache asynchronously (call from setup or CmdlineEnter).
function M.preload()
  if cached_executables then
    return
  end
  scan_path_async(function(results)
    cached_executables = results
    cache_timestamp = vim.uv.now() / 1000
  end)
end

return M
