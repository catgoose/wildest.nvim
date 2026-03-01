---@mod wildest.util Utilities
---@brief [[
---General-purpose utility functions used throughout wildest.nvim.
---Includes string manipulation, path handling, and project root detection.
---@brief ]]

local M = {}

---Escape special characters in a Vim pattern.
---@param str string
---@return string
function M.escape_pattern(str)
  return vim.fn.escape(str, "\\.*~[]^$")
end

--- Escape special characters for use in Lua pattern
---@param str string
---@return string
function M.escape_lua_pattern(str)
  return (str:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%0"))
end

--- Get display width of a string (handles multibyte)
---@param str string
---@return integer
function M.strdisplaywidth(str)
  return vim.fn.strdisplaywidth(str)
end

--- Truncate string to fit within max display width
---@param str string
---@param max_width integer
---@param suffix? string suffix to append when truncated (default '...')
---@return string
function M.truncate(str, max_width, suffix)
  suffix = suffix or "..."
  local width = M.strdisplaywidth(str)
  if width <= max_width then
    return str
  end

  local suffix_width = M.strdisplaywidth(suffix)
  local target = max_width - suffix_width
  if target <= 0 then
    return suffix:sub(1, max_width)
  end

  -- Truncate by characters, checking display width
  local result = ""
  local cur_width = 0
  for _, char in utf8.codes(str) do
    local c = utf8.char(char)
    local cw = M.strdisplaywidth(c)
    if cur_width + cw > target then
      break
    end
    result = result .. c
    cur_width = cur_width + cw
  end

  return result .. suffix
end

--- Normalize path separators and expand ~
---@param path string
---@return string
function M.normalize_path(path)
  path = path:gsub("\\", "/")
  if path:sub(1, 1) == "~" then
    local home = vim.env.HOME or vim.fn.expand("~")
    path = home .. path:sub(2)
  end
  return path
end

--- Shorten path with ~ for home directory
---@param path string
---@return string
function M.shorten_home(path)
  local home = vim.env.HOME or vim.fn.expand("~")
  if home and path:sub(1, #home) == home then
    return "~" .. path:sub(#home + 1)
  end
  return path
end

--- Parse percentage string (e.g. "75%") to integer given total.
---@param str string
---@param total number
---@return integer|nil value or nil if str is not a "N%" string
function M.parse_percent(str, total)
  if type(str) ~= "string" then
    return nil
  end
  local pct = str:match("^(%d+)%%$")
  if pct then
    return math.floor(tonumber(pct) / 100 * total)
  end
  return nil
end

--- Check if a string is empty or nil
---@param str? string
---@return boolean
function M.is_empty(str)
  return str == nil or str == ""
end

--- Split a command string respecting quotes
---@param cmdline string
---@return string cmd, string args
function M.split_cmd_args(cmdline)
  local cmd = cmdline:match("^%s*(%S+)")
  local args = ""
  if cmd then
    args = cmdline:sub(#cmd + 1):match("^%s*(.*)$") or ""
  end
  return cmd or "", args
end

--- Return the first n elements of a list (or the original list if #list <= n)
---@param list table
---@param n integer
---@return table
function M.take(list, n)
  if #list <= n then
    return list
  end
  local out = {}
  for i = 1, n do
    out[i] = list[i]
  end
  return out
end

--- Project root detection cache
local project_root_cache = {}

--- Find the project root by searching upward for marker files/directories
--- Uses findfile/finddir to search upward, stopping at home directory.
---
---@param markers? string[] root markers (default: { '.git', '.hg' })
---@param path? string starting path (default: cwd)
---@return string root path, or '' if not found
function M.project_root(markers, path)
  markers = markers or { ".git", ".hg" }
  path = path or vim.fn.getcwd()

  -- Check cache
  local cache_key = path .. ":" .. table.concat(markers, ",")
  if project_root_cache[cache_key] then
    return project_root_cache[cache_key]
  end

  local home = vim.fn.expand("~")
  local find_path = path .. ";" .. home

  for _, marker in ipairs(markers) do
    -- Try as file first, then as directory
    local result = vim.fn.findfile(marker, find_path)
    if result == "" then
      result = vim.fn.finddir(marker, find_path)
    end

    if result ~= "" then
      local root = vim.fn.fnamemodify(result, ":~:h")
      project_root_cache[cache_key] = root
      return root
    end
  end

  project_root_cache[cache_key] = ""
  return ""
end

--- Clear the project root cache
function M.clear_project_root_cache()
  project_root_cache = {}
end

--- Determine the "expand" type from pipeline data.
--- Returns "file", "buffer", "help", or nil.
---@param data table
---@return string|nil
function M.detect_expand(data)
  if data.expand then
    local e = data.expand
    if e == "file" or e == "file_in_path" or e == "dir" then
      return "file"
    end
    if e == "buffer" then
      return "buffer"
    end
    if e == "help" then
      return "help"
    end
    return nil
  end
  if data.cmd then
    local cmd = data.cmd:lower()
    if cmd == "help" or cmd == "h" then
      return "help"
    end
    if cmd == "buffer" or cmd == "b" or cmd == "sbuffer" or cmd == "sb" then
      return "buffer"
    end
    if
      cmd == "edit"
      or cmd == "e"
      or cmd == "split"
      or cmd == "sp"
      or cmd == "vsplit"
      or cmd == "vs"
      or cmd == "tabedit"
      or cmd == "tabe"
    then
      return "file"
    end
  end
  return nil
end

return M
