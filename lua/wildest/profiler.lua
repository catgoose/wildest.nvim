---@mod wildest.profiler Pipeline Profiler
---@brief [[
---Pipeline profiler — measures execution time of pipeline steps.
---@brief ]]

local M = {}

local _profiles = {}
local _enabled = false

--- Enable profiling
function M.enable()
  _enabled = true
  _profiles = {}
end

--- Disable profiling
function M.disable()
  _enabled = false
end

--- Check if profiling is enabled
---@return boolean
function M.is_enabled()
  return _enabled
end

--- Record a profile entry
---@param name string Step name
---@param elapsed_ms number Elapsed time in milliseconds
---@param input_count? integer Number of input candidates
---@param output_count? integer Number of output candidates
function M.record(name, elapsed_ms, input_count, output_count)
  if not _enabled then
    return
  end
  table.insert(_profiles, {
    name = name,
    elapsed_ms = elapsed_ms,
    input_count = input_count,
    output_count = output_count,
    timestamp = vim.uv.hrtime(),
  })
end

--- Get all profile entries
---@return table[]
function M.get()
  return _profiles
end

--- Clear profile data
function M.clear()
  _profiles = {}
end

--- Format profile data as a readable string
---@return string
function M.format()
  if #_profiles == 0 then
    return "No profile data. Enable with :WildestProfile start"
  end

  local lines = { "Pipeline Profile:" }
  local total = 0

  for _, p in ipairs(_profiles) do
    local line = string.format("  %-30s %6.2f ms", p.name, p.elapsed_ms)
    if p.input_count and p.output_count then
      line = line .. string.format("  (%d → %d)", p.input_count, p.output_count)
    end
    table.insert(lines, line)
    total = total + p.elapsed_ms
  end

  table.insert(lines, string.format("  %-30s %6.2f ms", "TOTAL", total))
  return table.concat(lines, "\n")
end

return M
