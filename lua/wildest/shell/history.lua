---@mod wildest.shell.history Shell History Reader
---@brief [[
---Reads shell history from bash, zsh, or fish history files.
---Supports auto-detection of shell type and history file location.
---@brief ]]

local M = {}

--- Per-session cache: { [session_id] = string[] }
local session_cache = {}

--- Detect the user's shell and history file path.
---@return string path, string shell_type
function M.detect_histfile()
  local shell = vim.o.shell
  if shell == "" then
    shell = vim.env.SHELL or "bash"
  end

  local base = vim.fs.basename(shell)

  if base == "zsh" then
    local path = vim.env.HISTFILE or (vim.env.HOME .. "/.zsh_history")
    return path, "zsh"
  elseif base == "fish" then
    local xdg = vim.env.XDG_DATA_HOME or (vim.env.HOME .. "/.local/share")
    return xdg .. "/fish/fish_history", "fish"
  else
    -- Default to bash
    local path = vim.env.HISTFILE or (vim.env.HOME .. "/.bash_history")
    return path, "bash"
  end
end

--- Parse bash history (one command per line, read from end).
---@param lines string[]
---@param max integer
---@return string[]
local function parse_bash(lines, max)
  local entries = {}
  local seen = {}
  for i = #lines, 1, -1 do
    local line = lines[i]
    if line and line ~= "" and not seen[line] then
      seen[line] = true
      entries[#entries + 1] = line
      if #entries >= max then
        break
      end
    end
  end
  return entries
end

--- Parse zsh history (extended format `: timestamp:duration;command` or plain).
---@param lines string[]
---@param max integer
---@return string[]
local function parse_zsh(lines, max)
  local entries = {}
  local seen = {}
  for i = #lines, 1, -1 do
    local line = lines[i]
    if line and line ~= "" then
      -- Extended format: `: 1234567890:0;command`
      local cmd = line:match("^: %d+:%d+;(.+)$")
      if not cmd then
        cmd = line
      end
      if cmd ~= "" and not seen[cmd] then
        seen[cmd] = true
        entries[#entries + 1] = cmd
        if #entries >= max then
          break
        end
      end
    end
  end
  return entries
end

--- Parse fish history (YAML-like `- cmd: command` format).
---@param lines string[]
---@param max integer
---@return string[]
local function parse_fish(lines, max)
  local entries = {}
  local seen = {}
  -- Fish stores entries as `- cmd: command\n  when: timestamp`
  -- Collect all commands first, then reverse for most-recent-first
  local all_cmds = {}
  for _, line in ipairs(lines) do
    local cmd = line:match("^%- cmd: (.+)$")
    if cmd and cmd ~= "" then
      all_cmds[#all_cmds + 1] = cmd
    end
  end
  -- Iterate from end for most recent first
  for i = #all_cmds, 1, -1 do
    local cmd = all_cmds[i]
    if not seen[cmd] then
      seen[cmd] = true
      entries[#entries + 1] = cmd
      if #entries >= max then
        break
      end
    end
  end
  return entries
end

--- Read shell history entries (most recent first, deduplicated).
---@param opts? { history_file?: string, history_max?: integer }
---@param ctx? { session_id?: integer }
---@return string[]
function M.read(opts, ctx)
  opts = opts or {}
  local max = opts.history_max or 100

  -- Check session cache
  if ctx and ctx.session_id then
    local cached = session_cache[ctx.session_id]
    if cached then
      return cached
    end
  end

  local hist_path, shell_type
  if opts.history_file and opts.history_file ~= "auto" then
    hist_path = opts.history_file
    -- Guess shell type from path
    if hist_path:find("zsh") then
      shell_type = "zsh"
    elseif hist_path:find("fish") then
      shell_type = "fish"
    else
      shell_type = "bash"
    end
  else
    hist_path, shell_type = M.detect_histfile()
  end

  local stat = vim.uv.fs_stat(hist_path)
  if not stat then
    return {}
  end

  local lines = vim.fn.readfile(hist_path)
  if not lines or #lines == 0 then
    return {}
  end

  local entries
  if shell_type == "zsh" then
    entries = parse_zsh(lines, max)
  elseif shell_type == "fish" then
    entries = parse_fish(lines, max)
  else
    entries = parse_bash(lines, max)
  end

  -- Cache per session
  if ctx and ctx.session_id then
    session_cache[ctx.session_id] = entries
  end

  return entries
end

--- Clear the session cache (exposed for testing).
function M._clear_cache()
  session_cache = {}
end

return M
