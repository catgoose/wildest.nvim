---@mod wildest.buffer_search Buffer Search Engine
---@brief [[
---Shared buffer search engine used by search and substitute pipelines.
---Supports vim.regex (default) or external tools like rg/grep for large files.
---@brief ]]

local pipeline_mod = require("wildest.pipeline")

local M = {}

-- Track active job for cleanup
local active_job = nil

--- Cancel any running search job.
function M.cancel()
  if active_job then
    pcall(function()
      active_job:kill("sigterm")
    end)
    active_job = nil
  end
end

--- Search buffer lines using vim.regex (synchronous).
---@param lines string[] buffer lines
---@param pattern string regex pattern
---@param max_results integer
---@return string[] matches
function M.search_vim(lines, pattern, max_results)
  local matches = {}
  local seen = {}

  local ok, regex = pcall(vim.regex, pattern)
  if not ok or not regex then
    return matches
  end

  for _, line in ipairs(lines) do
    local s = regex:match_str(line)
    if s then
      local trimmed = vim.trim(line)
      if trimmed ~= "" and not seen[trimmed] then
        seen[trimmed] = true
        matches[#matches + 1] = trimmed
        if #matches >= max_results then
          break
        end
      end
    end
  end

  return matches
end

--- Search buffer lines using fuzzy matching (synchronous fallback).
---@param lines string[] buffer lines
---@param pattern string search query
---@param max_results integer
---@param seen? table<string, boolean> already-seen lines to skip
---@return string[] matches
function M.search_fuzzy(lines, pattern, max_results, seen)
  seen = seen or {}
  local filter = require("wildest.filter")
  local matches = {}

  for _, line in ipairs(lines) do
    local trimmed = vim.trim(line)
    if trimmed ~= "" and not seen[trimmed] and filter.has_match(pattern, trimmed) then
      seen[trimmed] = true
      matches[#matches + 1] = trimmed
      if #matches >= max_results then
        break
      end
    end
  end

  return matches
end

---@return string[] command
local function detect_search_cmd()
  if vim.fn.executable("rg") == 1 then
    return { "rg", "--color=never", "--no-heading", "--no-filename", "--no-line-number" }
  elseif vim.fn.executable("grep") == 1 then
    return { "grep", "--color=never" }
  end
  return {}
end

--- Run an external search tool asynchronously (callback-based).
--- Spawns rg/grep against a file and calls on_done with results.
---@param cmd string[] base command (e.g. from resolve_engine)
---@param pattern string search pattern
---@param filepath string file to search
---@param max_results integer
---@param on_done fun(matches: string[]|nil, err: string|nil) callback
function M.run_external(cmd, pattern, filepath, max_results, on_done)
  M.cancel()

  local search_cmd = vim.list_extend({}, cmd)
  if search_cmd[1] == "rg" then
    table.insert(search_cmd, "--max-count=" .. max_results)
  end
  table.insert(search_cmd, pattern)
  table.insert(search_cmd, filepath)

  active_job = vim.system(search_cmd, { text = true }, function(res)
    active_job = nil
    vim.schedule(function()
      -- rg/grep exit 1 = no matches (not an error)
      if res.code ~= 0 and res.code ~= 1 then
        on_done(nil, string.format("buffer search failed: %s", res.stderr or ""))
        return
      end

      local lines = vim.split(res.stdout or "", "\n", { trimempty = true })
      local matches = {}
      local seen = {}

      for _, line in ipairs(lines) do
        local trimmed = vim.trim(line)
        if trimmed ~= "" and not seen[trimmed] then
          seen[trimmed] = true
          matches[#matches + 1] = trimmed
          if #matches >= max_results then
            break
          end
        end
      end

      on_done(matches, nil)
    end)
  end)
end

--- Get the filepath of the current buffer, or nil if unsaved.
---@return string|nil
function M.current_buffer_path()
  local bufnr = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    return nil
  end
  -- Check if file exists on disk
  local stat = vim.uv.fs_stat(name)
  if not stat then
    return nil
  end
  return name
end

--- Resolve engine option into a search command, or nil for vim.regex.
---@param engine_val any
---@return string[]|nil command, or nil to use vim.regex
function M.resolve_engine(engine_val)
  if engine_val == nil or engine_val == false or engine_val == "vim" then
    return nil
  end
  if engine_val == true or engine_val == "fast" then
    local cmd = detect_search_cmd()
    if #cmd > 0 then
      return cmd
    end
    return nil
  end
  if type(engine_val) == "string" then
    -- Bare tool name like "rg" or "grep"
    if vim.fn.executable(engine_val) == 1 then
      if engine_val == "rg" then
        return { "rg", "--color=never", "--no-heading", "--no-filename", "--no-line-number" }
      elseif engine_val == "grep" then
        return { "grep", "--color=never" }
      end
      return { engine_val }
    end
    return nil
  end
  if type(engine_val) == "table" and type(engine_val[1]) == "string" then
    return engine_val
  end
  return nil
end

return M
