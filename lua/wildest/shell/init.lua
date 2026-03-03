---@mod wildest.shell Shell Pipeline
---@brief [[
---Shell command pipeline factory for `:!` commands.
---Provides completion from shell history, Vim `:!` history, executables,
---file arguments, and environment variables.
---@brief ]]

local history_mod = require("wildest.shell.history")

local M = {}

---@class wildest.ShellPipelineOpts
---@field history? boolean Include shell history file entries (default: true)
---@field history_file? string Path to shell history file (default: "auto")
---@field history_max? integer Max shell history entries (default: 100)
---@field vim_history? boolean Include Vim's :! command history (default: true)
---@field vim_history_max? integer Max Vim history entries (default: 50)
---@field complete_args? "file"|"none"|false Argument completion strategy (default: "file")
---@field env_vars? boolean Complete $VAR names (default: true)
---@field fuzzy? boolean Apply fuzzy filtering (default: false)
---@field frecency? boolean Apply frecency boosting (default: false)
---@field frecency_blend? number Frecency blend factor (default: 0.5)

--- Get Vim `:!` history entries (commands starting with `!`).
---@param max integer
---@param filter string prefix filter
---@return string[]
local function get_vim_bang_history(max, filter)
  local entries = {}
  local seen = {}
  local hist_nr = vim.fn.histnr(":")
  local lower_filter = filter:lower()

  for i = hist_nr, math.max(1, hist_nr - max * 2), -1 do
    local entry = vim.fn.histget(":", i)
    if entry and entry:sub(1, 1) == "!" then
      local cmd = entry:sub(2) -- strip leading !
      if cmd ~= "" then
        cmd = cmd:gsub("\n", " ")
        if not seen[cmd] and (filter == "" or cmd:lower():find(lower_filter, 1, true)) then
          seen[cmd] = true
          entries[#entries + 1] = cmd
          if #entries >= max then
            break
          end
        end
      end
    end
  end

  return entries
end

--- Create a shell command completion pipeline.
---@param opts? wildest.ShellPipelineOpts
---@return wildest.PipelineStep[] pipeline
function M.shell_pipeline(opts)
  opts = opts or {}
  local do_history = opts.history ~= false
  local do_vim_history = opts.vim_history ~= false
  local history_max = opts.history_max or 100
  local vim_history_max = opts.vim_history_max or 50
  local complete_args = opts.complete_args
  if complete_args == nil then
    complete_args = "file"
  end
  local do_env_vars = opts.env_vars ~= false

  -- Track whether we're in Phase 1 (command name) or Phase 2 (arguments)
  -- and what kind of completion is active, so wrap_result can set the right output/expand.
  local phase_info = {}

  --- Parse and complete stage
  local function parse_and_complete(ctx, input)
    if not input or input == "" then
      return false
    end
    if ctx.cmdtype ~= ":" then
      return false
    end

    -- Match :! commands, :terminal, :term
    local arg
    arg = input:match("^%s*!(.*)$")
    if not arg then
      arg = input:match("^%s*te?r?m?i?n?a?l?%s+(.+)$")
      if not arg then
        arg = input:match("^%s*term?%s+(.+)$")
      end
    end
    if not arg then
      return false
    end

    -- Determine phase: does arg contain a space (meaning we're completing arguments)?
    local has_space = arg:find("%s")

    if not has_space then
      -- Phase 1: command name completion
      phase_info.phase = "command"
      phase_info.arg = arg
      ctx.arg = arg

      local candidates = {}
      local seen = {}

      -- Shell history entries (filtered by typed prefix)
      if do_history then
        local shell_entries = history_mod.read({
          history_file = opts.history_file,
          history_max = history_max,
        }, ctx)
        local lower_arg = arg:lower()
        for _, entry in ipairs(shell_entries) do
          if arg == "" or entry:lower():find(lower_arg, 1, true) then
            if not seen[entry] then
              seen[entry] = true
              candidates[#candidates + 1] = entry
            end
          end
        end
      end

      -- Vim :! history entries
      if do_vim_history then
        local vim_entries = get_vim_bang_history(vim_history_max, arg)
        for _, entry in ipairs(vim_entries) do
          if not seen[entry] then
            seen[entry] = true
            candidates[#candidates + 1] = entry
          end
        end
      end

      -- Executable completions (only when arg is non-empty to avoid thousands of results)
      if arg ~= "" then
        local ok, shellcmds = pcall(vim.fn.getcompletion, arg, "shellcmd")
        if ok and shellcmds then
          for _, cmd in ipairs(shellcmds) do
            if not seen[cmd] then
              seen[cmd] = true
              candidates[#candidates + 1] = cmd
            end
          end
        end
      end

      if #candidates == 0 then
        return false
      end
      return candidates
    else
      -- Phase 2: argument completion
      -- Extract the last word being typed
      local last_word = arg:match("(%S+)$") or ""

      -- Environment variable completion
      if do_env_vars and last_word:sub(1, 1) == "$" then
        phase_info.phase = "env"
        phase_info.arg = last_word
        ctx.arg = last_word

        local prefix = last_word:sub(2) -- strip $
        local ok, env_vars = pcall(vim.fn.getcompletion, prefix, "environment")
        if ok and env_vars and #env_vars > 0 then
          local candidates = {}
          for _, var in ipairs(env_vars) do
            candidates[#candidates + 1] = "$" .. var
          end
          return candidates
        end
        return false
      end

      -- File completion
      if complete_args == "file" then
        phase_info.phase = "file"
        phase_info.arg = last_word
        ctx.arg = last_word

        local ok, files = pcall(vim.fn.getcompletion, last_word, "file")
        if ok and files and #files > 0 then
          return files
        end
        return false
      end

      return false
    end
  end

  -- Build pipeline
  local pipeline = { parse_and_complete }

  -- Dedup
  table.insert(pipeline, require("wildest.filter.uniq").uniq_filter())

  -- Optional fuzzy filter
  if opts.fuzzy then
    table.insert(pipeline, require("wildest.filter").fuzzy_filter())
  end

  -- Optional frecency boost
  if opts.frecency then
    table.insert(pipeline, require("wildest.frecency").boost({ blend = opts.frecency_blend or 0.5 }))
  end

  --- Result wrapper stage
  local function wrap_result(ctx, candidates)
    if type(candidates) ~= "table" or #candidates == 0 then
      return false
    end

    local phase = phase_info.phase or "command"
    local data = {
      input = ctx.input or "",
      arg = phase_info.arg or ctx.arg or "",
    }

    local result = {
      value = candidates,
      data = data,
    }

    if phase == "command" then
      -- Replace everything after !
      data.expand = "shellcmd"
      result.output = function(rdata, candidate)
        local inp = rdata.input or ""
        local a = rdata.arg or ""
        if a ~= "" then
          local prefix = inp:sub(1, #inp - #a)
          return prefix .. candidate
        end
        return inp .. candidate
      end
    elseif phase == "file" then
      -- Replace only the last token
      data.expand = "file"
      result.output = function(rdata, candidate)
        local inp = rdata.input or ""
        local a = rdata.arg or ""
        if a ~= "" then
          local prefix = inp:sub(1, #inp - #a)
          return prefix .. candidate
        end
        return inp .. candidate
      end
    elseif phase == "env" then
      -- Replace only the $VAR token
      data.expand = "environment"
      result.output = function(rdata, candidate)
        local inp = rdata.input or ""
        local a = rdata.arg or ""
        if a ~= "" then
          local prefix = inp:sub(1, #inp - #a)
          return prefix .. candidate
        end
        return inp .. candidate
      end
    end

    return result
  end

  table.insert(pipeline, wrap_result)

  return pipeline
end

return M
