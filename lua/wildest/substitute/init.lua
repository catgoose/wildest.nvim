---@mod wildest.substitute Substitute Pipeline
---@brief [[
---Substitute/global command completion pipeline.
---Shows matching buffer lines for :s/pattern/ and :g/pattern/ commands.
---Supports vim.regex (default) or external tools like rg/grep via the engine option.
---@brief ]]

local M = {}

--- Skip whitespace in cmdline starting at pos
---@param cmdline string
---@param pos integer 1-indexed position
---@return integer new position
local function skip_whitespace(cmdline, pos)
  while pos <= #cmdline and cmdline:sub(pos, pos):match("%s") do
    pos = pos + 1
  end
  return pos
end

--- Skip a range specification (line numbers, marks, patterns)
---@param cmdline string
---@param pos integer
---@return integer
local function skip_range(cmdline, pos)
  while pos <= #cmdline do
    local c = cmdline:sub(pos, pos)

    if c == "." or c == "$" or c == "%" then
      pos = pos + 1
    elseif c == "'" then
      pos = pos + 1
      if pos <= #cmdline then
        pos = pos + 1
      end
    elseif c:match("[0-9]") then
      while pos <= #cmdline and cmdline:sub(pos, pos):match("[0-9]") do
        pos = pos + 1
      end
    elseif c == "/" then
      pos = pos + 1
      while pos <= #cmdline and cmdline:sub(pos, pos) ~= "/" do
        if cmdline:sub(pos, pos) == "\\" then
          pos = pos + 1
        end
        pos = pos + 1
      end
      if pos <= #cmdline then
        pos = pos + 1
      end
    elseif c == "?" then
      pos = pos + 1
      while pos <= #cmdline and cmdline:sub(pos, pos) ~= "?" do
        if cmdline:sub(pos, pos) == "\\" then
          pos = pos + 1
        end
        pos = pos + 1
      end
      if pos <= #cmdline then
        pos = pos + 1
      end
    elseif c == "+" or c == "-" then
      pos = pos + 1
      while pos <= #cmdline and cmdline:sub(pos, pos):match("[0-9]") do
        pos = pos + 1
      end
    elseif c == "," or c == ";" then
      pos = pos + 1
    else
      break
    end

    pos = skip_whitespace(cmdline, pos)
  end

  return pos
end

-- Recognized substitute/global command names
local substitute_commands = {
  s = true,
  substitute = true,
  sub = true,
  smagic = true,
  sm = true,
  snomagic = true,
  sno = true,
  g = true,
  global = true,
  v = true,
  vglobal = true,
}

--- Parse a substitute or global command, extracting the search pattern.
---@param input string The full command-line input
---@return string|nil pattern The search pattern, or nil if not a substitute/global command
function M.parse_substitute_command(input)
  if not input or input == "" then
    return nil
  end

  local pos = 1

  -- Skip leading whitespace
  pos = skip_whitespace(input, pos)

  -- Skip range
  pos = skip_range(input, pos)

  -- Skip whitespace after range
  pos = skip_whitespace(input, pos)

  if pos > #input then
    return nil
  end

  -- Extract command name (lowercase alpha)
  local cmd_start = pos
  while pos <= #input and input:sub(pos, pos):match("[a-z]") do
    pos = pos + 1
  end
  local cmd = input:sub(cmd_start, pos - 1)

  if not substitute_commands[cmd] then
    return nil
  end

  -- After the command name, the next character is the delimiter
  if pos > #input then
    return nil
  end

  local delim = input:sub(pos, pos)

  -- Delimiter must be non-alphanumeric, non-space
  if delim:match("[%w%s]") then
    return nil
  end

  pos = pos + 1

  -- Extract pattern, handling escaped delimiters
  local pattern_start = pos
  while pos <= #input do
    local c = input:sub(pos, pos)
    if c == "\\" and pos + 1 <= #input then
      -- Skip escaped character
      pos = pos + 2
    elseif c == delim then
      break
    else
      pos = pos + 1
    end
  end

  local pattern = input:sub(pattern_start, pos - 1)

  if pattern == "" then
    return nil
  end

  return pattern
end

--- Create a substitute/global command pipeline
--- Searches current buffer lines matching the extracted pattern
---@param opts? table { max_results?: integer, fuzzy?: boolean, fuzzy_filter?: function, engine?: "fast"|"vim"|string|string[] }
---@return table pipeline array
function M.substitute_pipeline(opts)
  opts = opts or {}
  local max_results = opts.max_results or 50

  local buffer_search = require("wildest.buffer_search")

  -- Resolve engine: extract from engine.search table form if needed
  local engine_val = opts.engine
  if type(engine_val) == "table" and not engine_val[1] and engine_val.search then
    engine_val = engine_val.search
  end
  local search_cmd = buffer_search.resolve_engine(engine_val)

  local function substitute(ctx, input)
    if not input or input == "" then
      return false
    end

    -- Only handle command mode
    if ctx.cmdtype ~= ":" then
      return false
    end

    local pattern = M.parse_substitute_command(input)
    if not pattern then
      return false
    end

    local function make_result(matches)
      if #matches == 0 then
        return false
      end
      ctx.arg = pattern
      return {
        value = matches,
        data = {
          input = input,
          arg = pattern,
          route = "substitute",
        },
        output = function(_data, _candidate)
          return input
        end,
      }
    end

    -- Try async external engine if available and buffer is on disk
    local filepath = search_cmd and buffer_search.current_buffer_path()
    if filepath then
      local pipeline_mod = require("wildest.pipeline")
      local state = require("wildest.state")
      local run_id = ctx.run_id

      return function(async_ctx)
        buffer_search.run_external(
          search_cmd,
          pattern,
          filepath,
          max_results,
          function(matches, err)
            -- Stale check
            if run_id ~= state.get().run_id then
              return
            end
            if err then
              pipeline_mod.reject(async_ctx, err)
              return
            end
            if not matches or #matches == 0 then
              -- Fall back: try fuzzy if enabled and external found nothing
              if opts.fuzzy then
                local bufnr = vim.api.nvim_get_current_buf()
                local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
                matches = buffer_search.search_fuzzy(lines, pattern, max_results)
              end
              if not matches or #matches == 0 then
                pipeline_mod.reject(async_ctx, false)
                return
              end
            end
            ctx.arg = pattern
            pipeline_mod.resolve(async_ctx, {
              value = matches,
              data = { input = input, arg = pattern, route = "substitute" },
              output = function(_data, _candidate)
                return input
              end,
            })
          end
        )
      end
    end

    -- Sync fallback: vim.regex + optional fuzzy
    local bufnr = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    local matches = buffer_search.search_vim(lines, pattern, max_results)

    -- Fuzzy fallback when regex fails or finds nothing
    if #matches == 0 and opts.fuzzy then
      matches = buffer_search.search_fuzzy(lines, pattern, max_results)
    end

    return make_result(matches)
  end

  local pipeline = { substitute }

  if opts.fuzzy then
    local fuzzy_filter = opts.fuzzy_filter or require("wildest.filter").fuzzy_filter()
    table.insert(pipeline, fuzzy_filter)
  end

  return pipeline
end

return M
