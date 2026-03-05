---@mod wildest.engine Engine Resolution
---@brief [[
---Shared utility for resolving polymorphic engine option values.
---
---Engine values can be:
---  - `true`           → enable with auto-detected defaults
---  - `{ "cmd", ... }` → sequential array = custom command (string[])
---  - `{ key = val }`  → table with named keys = full options
---  - `function`       → custom engine function
---  - `false` / `nil`  → disabled
---@brief ]]

local M = {}

---@alias wildest.EngineValue
---| boolean
---| string[]
---| table
---| fun(ctx: table, input: string): any

--- Classify an engine value into a normalized form.
---@param val any Raw engine value
---@return "disabled"|"auto"|"command"|"opts"|"function" kind
---@return any normalized The value in a usable form
function M.resolve(val)
  if val == nil or val == false then
    return "disabled", nil
  end

  if val == true then
    return "auto", {}
  end

  if type(val) == "function" then
    return "function", val
  end

  if type(val) == "table" then
    -- Sequential array (command): first element is a string, no named keys
    if type(val[1]) == "string" then
      return "command", val
    end
    -- Table with named keys = options passthrough
    return "opts", val
  end

  -- Unknown — treat as disabled
  return "disabled", nil
end

--- Convert a resolved engine value into file_finder_pipeline opts.
---@param val any Raw engine.files value
---@return table|nil opts for file_finder_pipeline, or nil if disabled
function M.to_file_finder_opts(val)
  local kind, normalized = M.resolve(val)
  if kind == "disabled" then
    return nil
  end
  if kind == "auto" then
    return {}
  end
  if kind == "command" then
    return { file_command = normalized }
  end
  if kind == "function" then
    return { file_command = normalized }
  end
  if kind == "opts" then
    -- Direct passthrough — user provided full opts table
    return normalized
  end
  return nil
end

--- Convert a resolved engine value into exec_cache configuration.
---@param val any Raw engine.shell value
---@return table|nil opts { command?: string[]|function } or nil if disabled
function M.to_exec_cache_opts(val)
  local kind, normalized = M.resolve(val)
  if kind == "disabled" then
    return nil
  end
  if kind == "auto" then
    return {}
  end
  if kind == "command" then
    return { command = normalized }
  end
  if kind == "function" then
    return { command = normalized }
  end
  if kind == "opts" then
    return normalized
  end
  return nil
end

--- Convert a resolved engine value into help_cache configuration.
---@param val any Raw engine.help value
---@return table|nil opts { command?: string[]|function } or nil if disabled
function M.to_help_cache_opts(val)
  local kind, normalized = M.resolve(val)
  if kind == "disabled" then
    return nil
  end
  if kind == "auto" then
    return {}
  end
  if kind == "command" then
    return { command = normalized }
  end
  if kind == "function" then
    return { command = normalized }
  end
  if kind == "opts" then
    return normalized
  end
  return nil
end

return M
