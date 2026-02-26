---@mod wildest.cmdline.parser Cmdline Parser
---@brief [[
---Command-line parsing for argument extraction and command detection.
---@brief ]]

local commands = require("wildest.cmdline.commands")

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
      -- Mark reference
      pos = pos + 1
      if pos <= #cmdline then
        pos = pos + 1
      end
    elseif c:match("[0-9]") then
      while pos <= #cmdline and cmdline:sub(pos, pos):match("[0-9]") do
        pos = pos + 1
      end
    elseif c == "/" then
      -- Pattern: /pattern/
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
      -- Pattern: ?pattern?
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

--- Extract command name from cmdline
---@param cmdline string
---@param pos integer
---@return string cmd, integer new_pos
local function extract_command(cmdline, pos)
  if pos > #cmdline then
    return "", pos
  end

  local c = cmdline:sub(pos, pos)

  -- Special single-char commands
  if
    c == "!"
    or c == "@"
    or c == "&"
    or c == "#"
    or c == "<"
    or c == ">"
    or c == "~"
    or c == "="
  then
    return c, pos + 1
  end

  -- User-defined commands start with uppercase
  if c:match("[A-Z]") then
    local start = pos
    while pos <= #cmdline and cmdline:sub(pos, pos):match("[A-Za-z0-9]") do
      pos = pos + 1
    end
    return cmdline:sub(start, pos - 1), pos
  end

  -- Regular command (lowercase)
  local start = pos
  while pos <= #cmdline and cmdline:sub(pos, pos):match("[a-z]") do
    pos = pos + 1
  end

  return cmdline:sub(start, pos - 1), pos
end

--- Resolve abbreviated command to full name and expand type
---@param cmd string
---@return string expand_type
local function resolve_expand_type(cmd)
  if cmd == "" then
    return commands.EXPAND.COMMAND
  end

  -- Direct lookup
  local expand = commands.command_expand[cmd]
  if expand then
    return expand
  end

  -- Check modifiers
  if commands.modifiers[cmd] then
    return commands.EXPAND.COMMAND
  end

  -- User-defined commands (start with uppercase)
  -- Use Vim's command-complete attribute to determine the type (#159)
  if cmd:sub(1, 1):match("[A-Z]") then
    -- Try to get the command's completion type from Vim
    local ok, info = pcall(vim.api.nvim_parse_cmd, cmd .. " ", {})
    if ok and info and info.nargs then
      -- Fall through to file completion as a sensible default
    end
    return commands.EXPAND.CUSTOM
  end

  -- Try to match by checking getcompletion for command type
  -- This handles abbreviated built-in commands
  return commands.EXPAND.FILE
end

--- Parse a cmdline string into structured information
---@param cmdline string the current command line content
---@return table { cmd: string, expand: string, arg: string, pos: integer }
function M.parse(cmdline)
  if not cmdline or cmdline == "" then
    return { cmd = "", expand = commands.EXPAND.COMMAND, arg = "", pos = 1 }
  end

  local pos = 1

  -- Skip leading whitespace
  pos = skip_whitespace(cmdline, pos)

  -- Skip range
  pos = skip_range(cmdline, pos)

  -- Skip whitespace after range
  pos = skip_whitespace(cmdline, pos)

  -- Check for comment
  if pos <= #cmdline and cmdline:sub(pos, pos) == '"' then
    return { cmd = "", expand = commands.EXPAND.NOTHING, arg = "", pos = pos }
  end

  -- Extract command
  local cmd, cmd_end = extract_command(cmdline, pos)

  -- Check for command modifier — if so, parse the rest as a new command
  if commands.modifiers[cmd] then
    local rest_pos = skip_whitespace(cmdline, cmd_end)
    if rest_pos <= #cmdline then
      -- Handle bang after modifier
      if cmdline:sub(rest_pos, rest_pos) == "!" then
        rest_pos = rest_pos + 1
        rest_pos = skip_whitespace(cmdline, rest_pos)
      end
      -- Recursively parse the rest
      local sub = M.parse(cmdline:sub(rest_pos))
      sub.pos = sub.pos + rest_pos - 1
      return sub
    end
    return { cmd = cmd, expand = commands.EXPAND.COMMAND, arg = "", pos = cmd_end }
  end

  -- Handle pipe and command chaining
  -- Look for the last | that's not inside quotes
  local pipe_pos = nil
  local in_quote = false
  local in_dquote = false
  for i = 1, #cmdline do
    local ch = cmdline:sub(i, i)
    if ch == "'" and not in_dquote then
      in_quote = not in_quote
    elseif ch == '"' and not in_quote then
      in_dquote = not in_dquote
    elseif ch == "|" and not in_quote and not in_dquote then
      -- Count preceding backslashes: odd = escaped pipe, even = literal pipe
      local num_backslashes = 0
      local j = i - 1
      while j >= 1 and cmdline:sub(j, j) == "\\" do
        num_backslashes = num_backslashes + 1
        j = j - 1
      end
      if num_backslashes % 2 == 0 then
        pipe_pos = i
      end
    end
  end

  if pipe_pos and pipe_pos >= cmd_end then
    -- Parse the command after the last pipe
    local rest = cmdline:sub(pipe_pos + 1)
    if rest ~= "" then
      return M.parse(rest)
    end
  end

  -- Check if we're still completing the command name
  if cmd_end > #cmdline and pos <= #cmdline then
    return { cmd = cmd, expand = commands.EXPAND.COMMAND, arg = cmd, pos = pos }
  end

  -- Handle bang (!)
  local bang = false
  if cmd_end <= #cmdline and cmdline:sub(cmd_end, cmd_end) == "!" then
    bang = true
    cmd_end = cmd_end + 1
  end

  -- Get the argument part
  local arg_start = skip_whitespace(cmdline, cmd_end)
  local arg = ""
  if arg_start <= #cmdline then
    arg = cmdline:sub(arg_start)
  end

  -- Determine expand type
  local expand = resolve_expand_type(cmd)

  return {
    cmd = cmd,
    expand = expand,
    arg = arg,
    pos = arg_start,
    bang = bang,
  }
end

return M
