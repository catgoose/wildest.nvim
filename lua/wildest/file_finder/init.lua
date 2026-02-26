---@mod wildest.file_finder File Finder
---@brief [[
---File finder pipeline using fd, rg, or find.
---@brief ]]

local commands = require("wildest.cmdline.commands")
local parser = require("wildest.cmdline.parser")
local pipeline_mod = require("wildest.pipeline")
local result = require("wildest.pipeline.result")
local util = require("wildest.util")

local M = {}

local E = commands.EXPAND

-- Track active job for cleanup
local active_job = nil

--- Cancel any running file finder job (called on CmdlineLeave)
---@return nil
function M.cancel()
  if active_job then
    pcall(function()
      active_job:kill("sigterm")
    end)
    active_job = nil
  end
end

--- Build file finder command with optional query filter
---@param base_cmd string[] base command and arguments
---@param query string search query to filter files
---@return string[] command
local function build_cmd(base_cmd, query)
  local cmd = vim.list_extend({}, base_cmd)
  -- Append query as a filter argument if non-empty
  if query and query ~= "" then
    if cmd[1] == "fd" or cmd[1] == "fdfind" then
      table.insert(cmd, query)
    elseif cmd[1] == "find" then
      -- Replace the default find args with a name filter
      cmd = { "find", ".", "-type", "f", "-name", "*" .. query .. "*" }
    end
    -- rg --files doesn't support a filename filter; post-filter handles it
  end
  return cmd
end

---@return string[] command
local function detect_file_cmd()
  if vim.fn.executable("fd") == 1 then
    return { "fd", "-tf", "--color=never" }
  elseif vim.fn.executable("fdfind") == 1 then
    return { "fdfind", "-tf", "--color=never" }
  elseif vim.fn.executable("rg") == 1 then
    return { "rg", "--files", "--color=never" }
  else
    return { "find", ".", "-type", "f" }
  end
end

---@return string[] command
local function detect_dir_cmd()
  if vim.fn.executable("fd") == 1 then
    return { "fd", "-td", "--color=never" }
  elseif vim.fn.executable("fdfind") == 1 then
    return { "fdfind", "-td", "--color=never" }
  else
    return { "find", ".", "-type", "d" }
  end
end

--- Create a file finder pipeline using subprocess
---@param opts? table { file_command?: string[]|function, dir_command?: string[]|function, cmd?: string[], cwd?: string, max_results?: integer }
---@return table pipeline array
function M.file_finder_pipeline(opts)
  opts = opts or {}
  local file_cmd = opts.file_command or opts.cmd or detect_file_cmd()
  local dir_cmd = opts.dir_command or opts.cmd or detect_dir_cmd()
  local cwd = opts.cwd
  local max_results = opts.max_results or 5000

  local function finder(ctx, input)
    if not input or input == "" then
      return false
    end

    -- Only for : mode
    if ctx.cmdtype ~= ":" then
      return false
    end

    -- Parse cmdline to determine command type and extract argument
    local parsed = parser.parse(input)
    local expand = parsed.expand

    -- Only handle file/dir commands
    if expand ~= E.FILE and expand ~= E.DIR and expand ~= E.FILE_IN_PATH then
      return false
    end

    ctx.arg = parsed.arg
    ctx.cmd = parsed.cmd
    ctx.expand = expand

    -- Select the right base command for files vs directories
    local base_cmd = (expand == E.DIR) and dir_cmd or file_cmd
    if type(base_cmd) == "function" then
      base_cmd = base_cmd(ctx, parsed.arg)
    end

    -- Cancel any previous job
    M.cancel()

    local query = parsed.arg

    return function(finder_ctx)
      local job_cwd = cwd or vim.fn.getcwd()
      local cmd = build_cmd(base_cmd, query)

      active_job = vim.system(cmd, { cwd = job_cwd, text = true }, function(res)
        active_job = nil
        vim.schedule(function()
          -- Stale check
          local state = require("wildest.state")
          if finder_ctx.run_id ~= state.get().run_id then
            return
          end

          if res.code ~= 0 and res.code ~= 1 then
            pipeline_mod.reject(finder_ctx, "file finder failed: " .. (res.stderr or ""))
            return
          end

          local files = vim.split(res.stdout or "", "\n", { trimempty = true })

          files = util.take(files, max_results)

          pipeline_mod.resolve(finder_ctx, files)
        end)
      end)
    end
  end

  local pipeline = { finder }

  -- Add fuzzy filter (post-filter for rg which doesn't support filename filter)
  table.insert(pipeline, function(ctx, files)
    local query = ctx.arg or ""
    if query == "" then
      return files
    end

    local filter_ok, filter_mod = pcall(require, "wildest.filter")
    if filter_ok then
      local filtered = filter_mod.filter_sort(query, files)
      return filtered
    end
    return files
  end)

  table.insert(pipeline, result.result())

  return pipeline
end

return M
