local M = {}

local _t0 = vim.uv.hrtime()
local _entries = {}
local _flush_timer = nil

--- Add a log entry with timestamp
---@param source string module name
---@param event string event name
---@param data? table extra data
function M.log(source, event, data)
  local entry = {
    t = math.floor((vim.uv.hrtime() - _t0) / 1e6),
    src = source,
    evt = event,
  }
  if data then
    for k, v in pairs(data) do
      entry[k] = v
    end
  end
  _entries[#_entries + 1] = entry

  -- Auto-flush periodically via timer (works during cmdline mode)
  if not _flush_timer then
    _flush_timer = vim.fn.timer_start(500, function()
      _flush_timer = nil
      M.flush()
    end)
  end
end

--- Flush all entries to the log file
function M.flush()
  if #_entries == 0 then
    return
  end
  local lines = {}
  for _, entry in ipairs(_entries) do
    lines[#lines + 1] = vim.json.encode(entry)
  end
  _entries = {}

  local path = M.path()
  local f = io.open(path, "a")
  if f then
    f:write(table.concat(lines, "\n") .. "\n")
    f:close()
  end
end

--- Clear the log file
function M.clear()
  local path = M.path()
  local f = io.open(path, "w")
  if f then
    f:write("")
    f:close()
  end
  _entries = {}
end

--- Get the log file path
---@return string
function M.path()
  return vim.fn.stdpath("log") .. "/wildest.jsonl"
end

return M
