---@mod wildest.cmdline Cmdline Pipeline
---@brief [[
---Cmdline completion pipeline factory. Creates pipelines for command-line mode completion.
---@brief ]]

local cache = require("wildest.cache")
local commands = require("wildest.cmdline.commands")
local completions = require("wildest.cmdline.completions")
local parser = require("wildest.cmdline.parser")
local pipeline_mod = require("wildest.pipeline")

local M = {}

local E = commands.EXPAND

--- Create a cmdline completion pipeline
---@param opts? table { fuzzy?: boolean, fuzzy_filter?: function }
---@return table pipeline array
function M.cmdline_pipeline(opts)
  opts = opts or {}

  local parse_cache = cache.mru_cache(30)

  --- Parse stage: parse cmdline and get completions
  local function parse_and_complete(ctx, input)
    if not input or input == "" then
      return false
    end
    if ctx.cmdtype ~= ":" then
      return false
    end

    -- Check cache
    local cached = parse_cache.get(input)
    if cached then
      ctx.arg = cached.arg
      ctx.cmd = cached.cmd
      ctx.expand = cached.expand
      return cached.candidates
    end

    -- Parse the cmdline
    local parsed = parser.parse(input)
    ctx.arg = parsed.arg
    ctx.cmd = parsed.cmd
    ctx.expand = parsed.expand

    local candidates
    if parsed.expand == E.COMMAND then
      -- Completing command name
      candidates = completions.get_command_completions(parsed.arg)
    else
      -- Completing command arguments
      candidates = completions.get_completions(parsed)
    end

    if not candidates or #candidates == 0 then
      return false
    end

    -- Cache the result
    parse_cache.set(input, {
      candidates = candidates,
      arg = parsed.arg,
      cmd = parsed.cmd,
      expand = parsed.expand,
    })

    return candidates
  end

  --- Result wrapper stage
  local function wrap_result(ctx, candidates)
    if type(candidates) ~= "table" then
      return false
    end

    local data = {
      input = ctx.input or "",
      arg = ctx.arg or "",
      cmd = ctx.cmd or "",
      expand = ctx.expand or "",
    }

    -- For file completions, highlight only the filename portion (after the
    -- last path separator) so the common directory prefix isn't accented.
    if ctx.expand == E.FILE or ctx.expand == E.DIR or ctx.expand == E.FILE_IN_PATH then
      local last_sep = (ctx.arg or ""):match(".*/()")
      if last_sep then
        data.query = (ctx.arg or ""):sub(last_sep)
      end
    end

    -- For file completion, provide output/replace transforms
    local result = {
      value = candidates,
      data = data,
    }

    if ctx.expand == E.FILE or ctx.expand == E.DIR or ctx.expand == E.FILE_IN_PATH then
      -- For file completions, construct the full cmdline replacement
      result.output = function(rdata, candidate)
        local input = rdata.input or ""
        local arg = rdata.arg or ""
        -- Replace the arg portion of the input with the candidate
        if arg ~= "" then
          local prefix = input:sub(1, #input - #arg)
          return prefix .. candidate
        end
        return input .. candidate
      end
    elseif ctx.expand == E.COMMAND then
      -- For command completions, just use the command name
      result.output = function(_rdata, candidate)
        return candidate
      end
    else
      -- For other completions, replace the arg part
      result.output = function(rdata, candidate)
        local input = rdata.input or ""
        local arg = rdata.arg or ""
        if arg ~= "" then
          local prefix = input:sub(1, #input - #arg)
          return prefix .. candidate
        end
        return input .. candidate
      end
    end

    return result
  end

  local pipeline = { parse_and_complete, require("wildest.filter.uniq").uniq_filter() }

  -- Add fuzzy filter if requested
  if opts.fuzzy then
    local filter = opts.fuzzy_filter or require("wildest.filter").fuzzy_filter()
    table.insert(pipeline, filter)
  end

  table.insert(pipeline, wrap_result)

  return pipeline
end

return M
