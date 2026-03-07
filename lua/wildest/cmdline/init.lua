---@mod wildest.cmdline Cmdline Pipeline
---@brief [[
---Cmdline completion pipeline factory. Creates pipelines for command-line mode completion.
---@brief ]]

local cache = require("wildest.cache")
local commands = require("wildest.cmdline.commands")
local completions = require("wildest.cmdline.completions")
local log = require("wildest.log")
local parser = require("wildest.cmdline.parser")

local M = {}

local E = commands.EXPAND

--- Resolve file_finder opts from engine + legacy file_finder option.
---@param opts table
---@return table|nil file_finder_pipeline opts, or nil if disabled
local function resolve_file_finder(opts)
  -- Legacy option takes precedence if set explicitly
  if opts.file_finder ~= nil then
    if not opts.file_finder then
      return nil
    end
    if type(opts.file_finder) == "table" then
      return opts.file_finder
    end
    return {} -- file_finder = true
  end
  local engine = opts.engine
  if engine == nil or engine == "vim" then
    return nil
  end
  if engine == "fast" then
    return {}
  end
  if type(engine) == "table" and engine.files then
    return require("wildest.engine").to_file_finder_opts(engine.files)
  end
  return nil
end

--- Create a cmdline completion pipeline
---@param opts? wildest.CmdlinePipelineOpts
---@return table pipeline array
function M.cmdline_pipeline(opts)
  opts = opts or {}

  -- Resolve file_finder from engine or legacy option
  local ff_opts = resolve_file_finder(opts)

  -- When file_finder is enabled, use branch() so file/dir completions
  -- go through the async file_finder_pipeline (fd/rg/find) and everything
  -- else falls through to the normal sync path.
  if ff_opts then
    local branch_mod = require("wildest.pipeline.branch")
    local file_finder = require("wildest.file_finder").file_finder_pipeline(ff_opts)

    -- Build the non-file-finder pipeline (same opts minus file_finder/engine)
    local sync_opts = vim.tbl_extend("force", {}, opts)
    sync_opts.file_finder = nil
    sync_opts.engine = nil
    local sync_pipeline = M.cmdline_pipeline(sync_opts)

    return { branch_mod.branch(file_finder, sync_pipeline) }
  end

  local parse_cache = cache.mru_cache(30)

  --- Parse stage: parse cmdline and get completions
  local function parse_and_complete(ctx, input)
    log.log("cmdline", "parse_and_complete", { input = input, cmdtype = ctx.cmdtype })
    if not input then
      log.log("cmdline", "reject_nil_input")
      return false
    end
    if ctx.cmdtype ~= ":" then
      log.log("cmdline", "reject_wrong_cmdtype", { cmdtype = ctx.cmdtype })
      return false
    end

    -- before_cursor: complete only text before cursor position
    if opts.before_cursor then
      local pos = vim.fn.getcmdpos()
      if pos and pos > 0 then
        ctx._full_cmdline = input
        ctx._after_cursor = input:sub(pos)
        input = input:sub(1, pos - 1)
        ctx._before_cursor = input
        if input == "" then
          log.log("cmdline", "reject_empty_before_cursor")
          return false
        end
      end
    end

    -- Check cache
    local cached = parse_cache:get(input)
    if cached then
      log.log("cmdline", "cache_hit", { input = input, count = #cached.candidates })
      ctx.arg = cached.arg
      ctx.cmd = cached.cmd
      ctx.expand = cached.expand
      ctx.pos = cached.pos
      return cached.candidates
    end

    -- Parse the cmdline
    local parsed = parser.parse(input)
    ctx.arg = parsed.arg
    ctx.cmd = parsed.cmd
    ctx.expand = parsed.expand
    ctx.pos = parsed.pos

    local candidates
    if parsed.expand == E.COMMAND then
      -- Completing command name
      candidates = completions.get_command_completions(parsed.arg)
    else
      -- Completing command arguments
      candidates = completions.get_completions(parsed)
    end

    log.log("cmdline", "completions", {
      input = input,
      expand = parsed.expand,
      arg = parsed.arg,
      count = candidates and #candidates or 0,
    })

    if not candidates or #candidates == 0 then
      log.log("cmdline", "reject_no_candidates", { input = input })
      return false
    end

    -- Cache the result
    parse_cache:set(input, {
      candidates = candidates,
      arg = parsed.arg,
      cmd = parsed.cmd,
      expand = parsed.expand,
      pos = parsed.pos,
    })

    return candidates
  end

  --- Result wrapper stage
  local function wrap_result(ctx, candidates)
    if type(candidates) ~= "table" then
      return false
    end

    local data = {
      input = ctx._before_cursor or ctx.input or "",
      arg = ctx.arg or "",
      cmd = ctx.cmd or "",
      expand = ctx.expand or "",
      pos = ctx.pos,
      _after_cursor = ctx._after_cursor or "",
    }

    -- For file completions, highlight only the filename portion (after the
    -- last path separator) so the common directory prefix isn't accented.
    -- Also advance pos to the last segment for before_cursor positioning.
    if ctx.expand == E.FILE or ctx.expand == E.DIR or ctx.expand == E.FILE_IN_PATH then
      local last_sep = (ctx.arg or ""):match(".*/()")
      if last_sep then
        data.query = (ctx.arg or ""):sub(last_sep)
        if data.pos then
          data.pos = data.pos + last_sep - 1
        end
      end
    end

    -- For dot-separated completions (e.g. lua vim.api.nvim), highlight only
    -- the last segment so the common prefix isn't accented.
    -- Also advance pos past the last dot for before_cursor positioning.
    -- Skip file types where dots are part of filenames, not namespaces.
    if
      not data.query
      and ctx.expand ~= E.FILE
      and ctx.expand ~= E.DIR
      and ctx.expand ~= E.FILE_IN_PATH
    then
      local arg = ctx.arg or ""
      local last_dot = arg:find("%.[^.]*$")
      if last_dot then
        data.query = arg:sub(last_dot + 1)
        if data.pos then
          data.pos = data.pos + last_dot
        end
      end
    end

    -- For file completion, provide output/replace transforms
    local result = {
      value = candidates,
      data = data,
    }

    if ctx.expand == E.COMMAND then
      -- For command completions, just use the command name
      result.output = function(rdata, candidate)
        local after = rdata._after_cursor or ""
        return candidate .. after
      end
    else
      -- For file, arg, and other completions, replace the arg portion
      result.output = function(rdata, candidate)
        local input = rdata.input or ""
        local arg = rdata.arg or ""
        local after = rdata._after_cursor or ""
        if arg ~= "" then
          local prefix = input:sub(1, #input - #arg)
          return string.format("%s%s%s", prefix, candidate, after)
        end
        return string.format("%s%s%s", input, candidate, after)
      end
    end

    return result
  end

  local pipeline = { parse_and_complete }

  -- Sort buffer candidates by last-used timestamp
  if opts.sort_buffers_lastused then
    table.insert(pipeline, function(ctx, candidates)
      if type(candidates) ~= "table" or ctx.expand ~= E.BUFFER then
        return candidates
      end
      local bufs = vim.fn.getbufinfo({ buflisted = 1 })
      local lastused = {}
      for _, b in ipairs(bufs) do
        local name = b.name or ""
        local tail = vim.fn.fnamemodify(name, ":t")
        lastused[tail] = math.max(lastused[tail] or 0, b.lastused or 0)
        lastused[name] = math.max(lastused[name] or 0, b.lastused or 0)
      end
      table.sort(candidates, function(a, b)
        return (lastused[a] or 0) > (lastused[b] or 0)
      end)
      return candidates
    end)
  end

  table.insert(pipeline, require("wildest.filter.uniq").uniq_filter())

  -- Add fuzzy filter if requested
  if opts.fuzzy then
    local filter = opts.fuzzy_filter or require("wildest.filter").fuzzy_filter()
    table.insert(pipeline, filter)
  end

  table.insert(pipeline, wrap_result)

  return pipeline
end

return M
