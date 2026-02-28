---@mod wildest.cmdline.completions Completion Logic
---@brief [[
---Core completion logic for cmdline arguments.
---@brief ]]

local commands = require("wildest.cmdline.commands")

local M = {}

local E = commands.EXPAND

--- Map expand types to vim.fn.getcompletion type strings
local expand_to_complete = {
  [E.FILE] = "file",
  [E.DIR] = "dir",
  [E.BUFFER] = "buffer",
  [E.HELP] = "help",
  [E.OPTION] = "option",
  [E.COMMAND] = "command",
  [E.TAGS] = "tag",
  [E.COLOR] = "color",
  [E.COMPILER] = "compiler",
  [E.HIGHLIGHT] = "highlight",
  [E.AUGROUP] = "augroup",
  [E.FUNCTION] = "function",
  [E.USER_FUNC] = "function",
  [E.USER_COMMANDS] = "command",
  [E.FILE_IN_PATH] = "file_in_path",
  [E.ENVIRONMENT] = "environment",
  [E.EXPRESSION] = "expression",
  [E.LUA] = "lua",
  [E.EVENT] = "event",
  [E.PACKADD] = "packadd",
  [E.FILETYPE] = "filetype",
  [E.SHELLCMD] = "shellcmd",
  [E.SIGN] = "sign",
  [E.MESSAGES] = "messages",
  [E.HISTORY] = "history",
  [E.ARGLIST] = "arglist",
  [E.CHECKHEALTH] = "checkhealth",
  [E.SYNTAX] = "syntax",
}

--- Get completions for a parsed command context
---@param parsed table { cmd, expand, arg, pos }
---@return string[] candidates
function M.get_completions(parsed)
  local expand = parsed.expand
  local arg = parsed.arg or ""

  -- Nothing to complete
  if expand == E.NOTHING then
    return {}
  end

  -- User-defined commands: use cmdline completion which handles
  -- multi-arg user commands properly (#159)
  if expand == E.CUSTOM then
    local full_cmdline = parsed.cmd .. " " .. arg
    local ok, results = pcall(vim.fn.getcompletion, full_cmdline, "cmdline")
    if ok and results and #results > 0 then
      return results
    end
    -- Fallback: try completing just the last word as a file
    local last_arg = arg:match("(%S*)$") or arg
    ok, results = pcall(vim.fn.getcompletion, last_arg, "file")
    if ok and results then
      return results
    end
    return {}
  end

  -- Map to vim completion type
  local complete_type = expand_to_complete[expand]
  if not complete_type then
    complete_type = "cmdline"
  end

  -- Use vim.fn.getcompletion for most types
  local ok, results = pcall(vim.fn.getcompletion, arg, complete_type)
  if not ok or not results then
    return {}
  end

  -- getcompletion for "lua" type returns field names without the base prefix
  -- (e.g. "vim." returns {"api","fn",...} not {"vim.api","vim.fn",...}).
  -- Prepend the base so candidates match the full expression the user typed.
  if expand == E.LUA then
    local base = arg:match("^(.*%.)") or ""
    if base ~= "" then
      for i, r in ipairs(results) do
        results[i] = base .. r
      end
    end
  end

  return results
end

--- Get command completions (for completing command names)
---@param prefix string
---@return string[]
function M.get_command_completions(prefix)
  local ok, results = pcall(vim.fn.getcompletion, prefix, "command")
  if ok and results then
    return results
  end
  return {}
end

return M
