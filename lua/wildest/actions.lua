---@mod wildest.actions Actions System
---@brief [[
---Extensible action system for wildest.nvim.
---Actions let users bind keys to named operations (open in split, send to
---quickfix, yank, etc.) or inline functions.
---@brief ]]

---@class wildest.ActionContext
---@field candidate string|nil Selected candidate (raw)
---@field candidates string[] All filtered candidates
---@field selected number 0-indexed, -1 if none
---@field result wildest.PipelineResult Full pipeline result
---@field data table Pipeline metadata (cmd, arg, expand, input, query)
---@field cmdtype string ':', '/', '?'
---@field input string Current cmdline input

local state = require("wildest.state")
local util = require("wildest.util")

local M = {}

--- Registry of named actions: name → function
---@type table<string, fun(ctx: wildest.ActionContext)>
local registry = {}

--- Helper: leave cmdline mode and then run fn on the next event loop tick.
--- Data must be captured BEFORE calling this, since CmdlineLeave clears state.
---@param fn fun()
local function leave_cmdline_and_run(fn)
  local esc = vim.api.nvim_replace_termcodes("<C-c>", true, false, true)
  vim.api.nvim_feedkeys(esc, "in", false)
  vim.schedule(fn)
end

--- Register a named action.
---@param name string Action name
---@param fn fun(ctx: wildest.ActionContext) Action function
function M.register(name, fn)
  registry[name] = fn
end

--- Resolve a string name or function to a callable action.
---@param name_or_fn string|fun(ctx: wildest.ActionContext)
---@return fun(ctx: wildest.ActionContext)
function M.resolve(name_or_fn)
  if type(name_or_fn) == "function" then
    return name_or_fn
  end
  if type(name_or_fn) == "string" then
    local fn = registry[name_or_fn]
    if not fn then
      error(string.format("[wildest] Unknown action: %s", name_or_fn))
    end
    return fn
  end
  error(
    string.format("[wildest] Action must be a string name or function, got %s", type(name_or_fn))
  )
end

--- List all registered action names (sorted).
---@return string[]
function M.list()
  local names = {}
  for name in pairs(registry) do
    names[#names + 1] = name
  end
  table.sort(names)
  return names
end

--- Build an ActionContext from the current state.
--- Returns nil if there is no active result.
---@return wildest.ActionContext|nil
function M.build_context()
  if not state.is_active() then
    return nil
  end
  local s = state.get()
  if not s.result then
    return nil
  end

  local candidates = s.result.value or {}
  local selected = s.selected
  local candidate = nil
  if selected >= 0 and selected < #candidates then
    candidate = candidates[selected + 1]
  end

  local data = s.result.data or {}

  return {
    candidate = candidate,
    candidates = candidates,
    selected = selected,
    result = s.result,
    data = data,
    cmdtype = s.cmdtype,
    input = s.previous_cmdline,
  }
end

--- Run an action: resolve it, build context, and pcall.
---@param name_or_fn string|fun(ctx: wildest.ActionContext)
function M.run(name_or_fn)
  local ok_resolve, fn = pcall(M.resolve, name_or_fn)
  if not ok_resolve then
    vim.notify(tostring(fn), vim.log.levels.ERROR)
    return
  end

  local ctx = M.build_context()
  if not ctx then
    return
  end

  local ok, err = pcall(fn, ctx)
  if not ok then
    vim.notify(string.format("[wildest] Action error: %s", tostring(err)), vim.log.levels.ERROR)
  end
end

-- ---------------------------------------------------------------------------
-- Built-in actions
-- ---------------------------------------------------------------------------

local detect_expand = util.detect_expand

--- Factory for open-in-split/vsplit/tab actions
---@param cmds { buffer: fun(escaped: string), help: fun(escaped: string), file: fun(escaped: string) }
local function make_open_action(cmds)
  return function(ctx)
    if not ctx.candidate then
      return
    end
    local candidate = ctx.candidate --[[@as string]]
    local escaped = vim.fn.fnameescape(candidate) ---@type string
    local expand = detect_expand(ctx.data)
    leave_cmdline_and_run(function()
      if expand == "buffer" then
        cmds.buffer(escaped)
      elseif expand == "help" then
        cmds.help(escaped)
      else
        cmds.file(escaped)
      end
    end)
  end
end

M.register(
  "open_split",
  make_open_action({
    buffer = function(e)
      vim.cmd.sbuffer(e)
    end,
    help = function(e)
      vim.cmd.help(e)
    end,
    file = function(e)
      vim.cmd.split(e)
    end,
  })
)

M.register(
  "open_vsplit",
  make_open_action({
    buffer = function(e)
      vim.api.nvim_cmd({ cmd = "sbuffer", args = { e }, mods = { vertical = true } }, {})
    end,
    help = function(e)
      vim.api.nvim_cmd({ cmd = "help", args = { e }, mods = { vertical = true } }, {})
    end,
    file = function(e)
      vim.cmd.vsplit(e)
    end,
  })
)

M.register(
  "open_tab",
  make_open_action({
    buffer = function(e)
      vim.api.nvim_cmd({ cmd = "sbuffer", args = { e }, mods = { tab = 1 } }, {})
    end,
    help = function(e)
      vim.api.nvim_cmd({ cmd = "help", args = { e }, mods = { tab = 1 } }, {})
    end,
    file = function(e)
      vim.cmd.tabedit(e)
    end,
  })
)

--- Build quickfix/loclist items from candidates
---@param candidates string[]
---@param expand string|nil
---@return table[]
local function build_list_items(candidates, expand)
  local items = {}
  for _, c in ipairs(candidates) do
    if expand == "file" then
      items[#items + 1] = { filename = c }
    elseif expand == "buffer" then
      local bufnr = vim.fn.bufnr(c)
      if bufnr ~= -1 then
        items[#items + 1] = { bufnr = bufnr }
      else
        items[#items + 1] = { text = c }
      end
    else
      items[#items + 1] = { text = c }
    end
  end
  return items
end

M.register("send_to_quickfix", function(ctx)
  if #ctx.candidates == 0 then
    return
  end
  local items = build_list_items(ctx.candidates, detect_expand(ctx.data))
  leave_cmdline_and_run(function()
    vim.fn.setqflist(items, "r")
    vim.cmd.copen()
  end)
end)

M.register("send_to_loclist", function(ctx)
  if #ctx.candidates == 0 then
    return
  end
  local items = build_list_items(ctx.candidates, detect_expand(ctx.data))
  leave_cmdline_and_run(function()
    vim.fn.setloclist(0, items, "r")
    vim.cmd.lopen()
  end)
end)

M.register("yank", function(ctx)
  if not ctx.candidate then
    return
  end
  vim.fn.setreg('"', ctx.candidate)
  vim.fn.setreg("+", ctx.candidate)
end)

M.register("toggle_preview", function(_)
  local preview = require("wildest.preview")
  preview.toggle()
  require("wildest.state").draw()
end)

return M
