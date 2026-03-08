---@mod wildest.preview File Preview System
---@brief [[
---Floating preview window that shows file contents, buffer contents, or help
---text for the currently selected completion candidate.
---@brief ]]

local renderer_util = require("wildest.renderer")
local util = require("wildest.util")

local M = {}

---@class wildest.PreviewConfig
---@field enabled boolean Show preview (default: true)
---@field position string Position: "left"|"right"|"top"|"bottom" (default: "right")
---@field anchor string Anchor: "screen"|"popup" (default: "screen")
---@field width integer|string Panel width for left/right (default: '50%')
---@field height integer|string Panel height for top/bottom (default: '50%')
---@field border string|table Border style (default: 'single')
---@field max_lines integer Max lines to read (default: 500)
---@field title boolean Show filename in title (default: true)
---@field gap integer|table|nil Gap between preview and edges/popup (default: nil)
---@field priority string Priority: "menu"|"preview" (default: "menu")

local preview_state = {
  enabled = false,
  config = nil, ---@type wildest.PreviewConfig|nil
  win = -1,
  buf = -1,
  ns_id = -1,
  last_candidate = nil,
}

--- Parse a dimension config (width or height) into an integer, clamped to [1, total].
--- Unlike renderer_util.parse_dimension, this clamps to valid preview bounds and
--- falls back to half the total for non-parseable input.
---@param dim integer|string|nil
---@param total integer
---@return integer
local function parse_dim(dim, total)
  if type(dim) == "number" then
    return math.max(1, math.min(dim, total))
  end
  if type(dim) == "string" then
    local val = util.parse_percent(dim, total)
    if val then
      return math.max(1, math.min(val, total))
    end
  end
  return math.floor(total / 2)
end

local detect_expand = util.detect_expand

--- Normalize a gap config (number, table, or nil) into a table with all 5 keys.
---@param raw integer|table|nil
---@return {top: integer, right: integer, bottom: integer, left: integer, between: integer}
local function normalize_gap(raw)
  if type(raw) == "number" then
    local g = math.max(0, raw)
    return { top = g, right = g, bottom = g, left = g, between = g }
  end
  if type(raw) == "table" then
    return {
      top = math.max(0, raw.top or 0),
      right = math.max(0, raw.right or 0),
      bottom = math.max(0, raw.bottom or 0),
      left = math.max(0, raw.left or 0),
      between = math.max(0, raw.between or 0),
    }
  end
  return { top = 0, right = 0, bottom = 0, left = 0, between = 0 }
end

-- Minimum space required to show a preview (including border).
-- 3 cols = 1 col content + 2 border cols; 1 row = 1 row content.
local MIN_PREVIEW_COLS = 3
local MIN_PREVIEW_ROWS = 1

--- Ensure preview buffer and namespace exist.
local function ensure_buf()
  if not vim.api.nvim_buf_is_valid(preview_state.buf) then
    preview_state.buf = vim.api.nvim_create_buf(false, true)
    vim.bo[preview_state.buf].bufhidden = "hide"
    vim.bo[preview_state.buf].buftype = "nofile"
    vim.bo[preview_state.buf].swapfile = false
  end
  if preview_state.ns_id == -1 then
    preview_state.ns_id = vim.api.nvim_create_namespace("wildest_preview")
  end
end

--- Safely expand a path, falling back to the raw string on error.
---@param path string
---@return string
local function safe_expand(path)
  local ok, result = pcall(vim.fn.expand, path)
  if ok and type(result) == "string" then
    return result
  end
  return path
end

--- Load file content into the preview buffer.
---@param path string
---@param cfg wildest.PreviewConfig
---@return string|nil title
--- Format file size into human-readable string.
---@param bytes integer
---@return string
local function format_size(bytes)
  if bytes < 1024 then
    return string.format("%d B", bytes)
  elseif bytes < 1024 * 1024 then
    return string.format("%.1f KB", bytes / 1024)
  elseif bytes < 1024 * 1024 * 1024 then
    return string.format("%.1f MB", bytes / (1024 * 1024))
  else
    return string.format("%.1f GB", bytes / (1024 * 1024 * 1024))
  end
end

--- Format unix permissions to rwx string.
---@param mode integer
---@return string
local function format_mode(mode)
  local bits = { "r", "w", "x" }
  local parts = {}
  for i = 8, 0, -1 do
    local idx = (8 - i) % 3 + 1
    parts[#parts + 1] = bit.band(mode, bit.lshift(1, i)) ~= 0 and bits[idx] or "-"
  end
  return table.concat(parts)
end

--- Type labels for stat.type values.
local type_labels = {
  file = "File",
  directory = "Directory",
  link = "Symlink",
  fifo = "FIFO (named pipe)",
  socket = "Socket",
  char = "Character device",
  block = "Block device",
}

--- Build metadata lines for a non-displayable file.
---@param path string
---@param stat table uv_fs_stat result
---@param label? string header label (default derived from stat.type)
---@return string[]
local function file_metadata(path, stat, label)
  label = label or (type_labels[stat.type] or stat.type)
  local lines = {
    "  " .. label,
    "",
  }
  lines[#lines + 1] = "  Path:      " .. path
  if stat.size and stat.size > 0 then
    lines[#lines + 1] = "  Size:      " .. format_size(stat.size)
  end
  lines[#lines + 1] = "  Mode:      " .. format_mode(stat.mode)

  local ft = vim.filetype.match({ filename = path })
  if ft then
    lines[#lines + 1] = "  Filetype:  " .. ft
  end

  -- Mime type via `file` command
  local ok, result = pcall(vim.fn.system, { "file", "--brief", "--mime-type", path })
  if ok and type(result) == "string" then
    local mime = vim.trim(result)
    if mime ~= "" and not mime:find("^cannot open") then
      lines[#lines + 1] = "  MIME:      " .. mime
    end
  end

  local mtime = stat.mtime
  if mtime then
    local ts = type(mtime) == "table" and mtime.sec or mtime
    lines[#lines + 1] = "  Modified:  " .. os.date("%Y-%m-%d %H:%M:%S", ts)
  end

  return lines
end

--- Load a directory listing into the preview buffer.
---@param path string
---@return string|nil title
local function load_directory(path)
  local expanded = safe_expand(path)
  local stat = vim.uv.fs_stat(expanded)
  if not stat or stat.type ~= "directory" then
    return nil
  end
  local handle = vim.uv.fs_scandir(expanded)
  if not handle then
    return nil
  end
  local entries = {}
  while true do
    local name, typ = vim.uv.fs_scandir_next(handle)
    if not name then
      break
    end
    entries[#entries + 1] = { name = name, type = typ }
  end
  table.sort(entries, function(a, b)
    -- Directories first, then alphabetical
    if a.type == "directory" and b.type ~= "directory" then
      return true
    end
    if a.type ~= "directory" and b.type == "directory" then
      return false
    end
    return a.name < b.name
  end)
  local lines = {
    "  " .. expanded,
    "  " .. #entries .. " entries",
    "",
  }
  for _, entry in ipairs(entries) do
    local suffix = entry.type == "directory" and "/" or ""
    local icon = entry.type == "directory" and " " or "  "
    lines[#lines + 1] = icon .. entry.name .. suffix
  end
  vim.api.nvim_buf_set_lines(preview_state.buf, 0, -1, false, lines)
  vim.bo[preview_state.buf].filetype = ""
  return vim.fs.basename(expanded) .. "/"
end

local function load_file(path, cfg)
  local expanded = safe_expand(path)
  local stat = vim.uv.fs_stat(expanded)
  if not stat then
    return nil
  end
  if stat.type == "directory" then
    return load_directory(expanded)
  end
  -- Special files (sockets, fifos, devices): show metadata
  if stat.type ~= "file" then
    local lines = file_metadata(expanded, stat)
    vim.api.nvim_buf_set_lines(preview_state.buf, 0, -1, false, lines)
    vim.bo[preview_state.buf].filetype = ""
    return vim.fs.basename(expanded)
  end
  -- Try to open — handles permission denied
  local fd = vim.uv.fs_open(expanded, "r", 438)
  if not fd then
    local lines = file_metadata(expanded, stat, "Permission denied")
    vim.api.nvim_buf_set_lines(preview_state.buf, 0, -1, false, lines)
    vim.bo[preview_state.buf].filetype = ""
    return vim.fs.basename(expanded)
  end
  -- Read first 1KB to check for binary content
  local chunk = vim.uv.fs_read(fd, 1024, 0)
  vim.uv.fs_close(fd)
  if chunk and chunk:find("\0") then
    local lines = file_metadata(expanded, stat, "Binary file")
    vim.api.nvim_buf_set_lines(preview_state.buf, 0, -1, false, lines)
    vim.bo[preview_state.buf].filetype = ""
    return vim.fs.basename(expanded)
  end
  local lines = vim.fn.readfile(expanded, "", cfg.max_lines or 500)
  vim.api.nvim_buf_set_lines(preview_state.buf, 0, -1, false, lines)
  local ft = vim.filetype.match({ filename = expanded })
  if ft then
    vim.bo[preview_state.buf].filetype = ft
  else
    vim.bo[preview_state.buf].filetype = ""
  end
  return vim.fs.basename(expanded)
end

--- Load buffer content into the preview buffer.
---@param name string
---@param cfg wildest.PreviewConfig
---@return string|nil title
local function load_buffer(name, cfg)
  local bufnr = vim.fn.bufnr(name)
  if bufnr == -1 or not vim.api.nvim_buf_is_valid(bufnr) then
    return nil
  end
  local max = cfg.max_lines or 500
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, max, false)
  vim.api.nvim_buf_set_lines(preview_state.buf, 0, -1, false, lines)
  local ft = vim.bo[bufnr].filetype
  if ft and ft ~= "" then
    vim.bo[preview_state.buf].filetype = ft
  else
    vim.bo[preview_state.buf].filetype = ""
  end
  local title = vim.fs.basename(name)
  return title
end

--- Search runtimepath doc/tags files for a help tag.
--- Returns the help file path and the tag marker pattern.
---@param tag string
---@return string|nil filepath, string|nil search_pattern
local function find_help_tag(tag)
  local tag_files = vim.api.nvim_get_runtime_file("doc/tags", true)
  for _, tf in ipairs(tag_files) do
    local f = io.open(tf, "r")
    if f then
      local dir = vim.fs.dirname(tf)
      for line in f:lines() do
        -- tags format: <tag>\t<filename>\t<search>
        local t, fname = line:match("^(%S+)\t(%S+)")
        if t == tag then
          f:close()
          local full = dir .. "/" .. fname
          if vim.uv.fs_stat(full) then
            return full
          end
        end
      end
      f:close()
    end
  end
  return nil
end

--- Load help content into the preview buffer.
--- Finds the help file and scrolls to the tag location.
---@param tag string
---@return string|nil title, integer|nil tag_line
local function load_help(tag)
  local help_file = find_help_tag(tag)
  if not help_file then
    return nil, nil
  end

  -- Find the tag line in the full file first
  local tag_marker = string.format("*%s*", tag)
  local tag_line = nil
  local f = io.open(help_file, "r")
  if f then
    local i = 0
    for line in f:lines() do
      i = i + 1
      if line:find(tag_marker, 1, true) then
        tag_line = i
        break
      end
    end
    f:close()
  end

  -- Load a window of lines around the tag (keeps buffer small for huge files)
  local start_line = 1
  if tag_line then
    start_line = math.max(1, tag_line - 5)
  end
  local lines = vim.fn.readfile(help_file, "", start_line + 500)
  if start_line > 1 then
    lines = vim.list_slice(lines, start_line)
  end
  vim.api.nvim_buf_set_lines(preview_state.buf, 0, -1, false, lines)
  vim.bo[preview_state.buf].filetype = "help"

  -- Adjust tag_line to be relative to the loaded chunk
  local scroll = tag_line and (tag_line - start_line + 1) or 1
  return tag, scroll
end

--- Load current buffer into preview, scrolled to matching line with highlights.
---@param candidate string the matching line text
---@param pattern string the search pattern
---@param cfg wildest.PreviewConfig
---@return string|nil title, integer|nil scroll_line
local function load_search(candidate, pattern, cfg)
  local bufnr = vim.api.nvim_get_current_buf()
  local max = cfg.max_lines or 500
  local all_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  -- Find the first line that matches the candidate text (search full buffer)
  local trimmed_candidate = vim.trim(candidate)
  local match_line = nil
  for i, line in ipairs(all_lines) do
    if vim.trim(line) == trimmed_candidate then
      match_line = i
      break
    end
  end

  -- Load a window of lines around the match
  local start_line = 1
  if match_line then
    start_line = math.max(1, match_line - math.floor(max / 4))
  end
  local end_line = math.min(#all_lines, start_line + max - 1)
  local lines = vim.list_slice(all_lines, start_line, end_line)

  vim.api.nvim_buf_set_lines(preview_state.buf, 0, -1, false, lines)

  local ft = vim.bo[bufnr].filetype
  if ft and ft ~= "" then
    vim.bo[preview_state.buf].filetype = ft
  else
    vim.bo[preview_state.buf].filetype = ""
  end

  -- Adjust match_line to be relative to the loaded chunk
  local scroll = match_line and (match_line - start_line + 1) or nil

  -- Highlight the matching line and pattern matches
  vim.api.nvim_buf_clear_namespace(preview_state.buf, preview_state.ns_id, 0, -1)
  if scroll then
    vim.api.nvim_buf_set_extmark(preview_state.buf, preview_state.ns_id, scroll - 1, 0, {
      end_col = #lines[scroll],
      hl_group = "CursorLine",
      hl_eol = true,
      priority = 100,
    })
  end

  -- Highlight all pattern matches in loaded lines with IncSearch
  local ok, regex = pcall(vim.regex, pattern)
  if ok and regex then
    for i, line in ipairs(lines) do
      local pos = 0
      while pos < #line do
        local s, e = regex:match_str(line:sub(pos + 1))
        if not s then
          break
        end
        vim.api.nvim_buf_set_extmark(preview_state.buf, preview_state.ns_id, i - 1, pos + s, {
          end_col = pos + e,
          hl_group = "IncSearch",
          priority = 200,
        })
        if e == s then
          break
        end
        pos = pos + e
      end
    end
  end

  local name = vim.api.nvim_buf_get_name(bufnr)
  local title = name ~= "" and vim.fs.basename(name) or "[buffer]"
  return title, scroll
end

--- Load vim option info into the preview buffer.
---@param candidate string option name (may have "no" prefix or trailing "?" / "=" / "&")
---@return string|nil title, integer|nil scroll_line
local function load_option(candidate)
  -- Strip common suffixes/prefixes: "nofoo", "foo?", "foo=", "foo&", "inv"
  local name = candidate:gsub("[?=&]+$", "")
  if name:match("^no") then
    local stripped = name:sub(3)
    local ok = pcall(vim.api.nvim_get_option_info2, stripped, {})
    if ok then
      name = stripped
    end
  end
  if name:match("^inv") then
    local stripped = name:sub(4)
    local ok = pcall(vim.api.nvim_get_option_info2, stripped, {})
    if ok then
      name = stripped
    end
  end

  local ok, info = pcall(vim.api.nvim_get_option_info2, name, {})
  if not ok or not info or not info.name then
    return nil, nil
  end

  -- Current value
  local val_ok, current = pcall(vim.api.nvim_get_option_value, name, {})
  if not val_ok then
    current = "?"
  end

  local lines = {
    "  " .. info.name,
    "",
  }

  -- Value
  if type(current) == "string" then
    lines[#lines + 1] = "  Value:    " .. (current == "" and "(empty)" or vim.inspect(current))
  else
    lines[#lines + 1] = "  Value:    " .. tostring(current)
  end

  -- Default
  if info.default ~= nil then
    if type(info.default) == "string" then
      lines[#lines + 1] = "  Default:  " .. (info.default == "" and "(empty)" or vim.inspect(info.default))
    else
      lines[#lines + 1] = "  Default:  " .. tostring(info.default)
    end
  end

  -- Type and scope
  lines[#lines + 1] = "  Type:     " .. (info.type or "unknown")
  lines[#lines + 1] = "  Scope:    " .. (info.scope or "unknown")
  if info.shortname and info.shortname ~= "" then
    lines[#lines + 1] = "  Short:    " .. info.shortname
  end

  -- Help text — find the option tag in help files and show surrounding lines
  local help_file = find_help_tag("'" .. name .. "'")
  if help_file then
    local tag_marker = string.format("*'%s'*", name)
    local f = io.open(help_file, "r")
    if f then
      local tag_line = nil
      local all = {}
      local i = 0
      for line in f:lines() do
        i = i + 1
        all[#all + 1] = line
        if not tag_line and line:find(tag_marker, 1, true) then
          tag_line = i
        end
      end
      f:close()
      if tag_line then
        lines[#lines + 1] = ""
        -- Show up to 30 lines of help starting from the tag
        local end_line = math.min(#all, tag_line + 30)
        for j = tag_line, end_line do
          lines[#lines + 1] = all[j]
        end
      end
    end
  end

  vim.api.nvim_buf_set_lines(preview_state.buf, 0, -1, false, lines)
  vim.bo[preview_state.buf].filetype = "help"
  return info.name, nil
end

--- Load highlight group info into the preview buffer.
---@param candidate string highlight group name
---@return string|nil title
local function load_highlight(candidate)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = candidate, link = false })
  if not ok or not hl then
    return nil
  end
  local ok_link, hl_link = pcall(vim.api.nvim_get_hl, 0, { name = candidate })
  local lines = {
    "  " .. candidate,
    "",
  }
  -- Show link target if linked
  if ok_link and hl_link and hl_link.link then
    lines[#lines + 1] = "  Link:     " .. hl_link.link
    lines[#lines + 1] = ""
  end
  -- Resolved attributes
  if hl.fg then
    lines[#lines + 1] = string.format("  fg:       #%06x", hl.fg)
  end
  if hl.bg then
    lines[#lines + 1] = string.format("  bg:       #%06x", hl.bg)
  end
  if hl.sp then
    lines[#lines + 1] = string.format("  sp:       #%06x", hl.sp)
  end
  local attrs = {}
  for _, attr in ipairs({ "bold", "italic", "underline", "undercurl", "strikethrough", "reverse", "standout" }) do
    if hl[attr] then
      attrs[#attrs + 1] = attr
    end
  end
  if #attrs > 0 then
    lines[#lines + 1] = "  Style:    " .. table.concat(attrs, ", ")
  end
  -- Sample text
  lines[#lines + 1] = ""
  lines[#lines + 1] = "  Sample text with this highlight"

  vim.api.nvim_buf_set_lines(preview_state.buf, 0, -1, false, lines)
  vim.bo[preview_state.buf].filetype = ""

  -- Apply the highlight to the sample line
  if preview_state.ns_id ~= -1 then
    vim.api.nvim_buf_clear_namespace(preview_state.buf, preview_state.ns_id, 0, -1)
    local sample_line = #lines - 1
    vim.api.nvim_buf_set_extmark(preview_state.buf, preview_state.ns_id, sample_line, 2, {
      end_col = #lines[#lines],
      hl_group = candidate,
      priority = 200,
    })
  end

  return candidate
end

--- Load Ex command info into the preview buffer.
---@param candidate string command name
---@return string|nil title, integer|nil scroll_line
local function load_command(candidate)
  -- Try user command first
  local cmds = vim.api.nvim_get_commands({})
  local info = cmds[candidate]
  -- Also check buffer-local
  if not info then
    local ok, buf_cmds = pcall(vim.api.nvim_buf_get_commands, 0, {})
    if ok then
      info = buf_cmds[candidate]
    end
  end

  if info then
    local lines = {
      "  :" .. candidate,
      "",
    }
    if info.definition and info.definition ~= "" then
      lines[#lines + 1] = "  Definition: " .. info.definition
    end
    if info.nargs and info.nargs ~= "" then
      lines[#lines + 1] = "  Args:       " .. info.nargs
    end
    if info.complete and info.complete ~= "" then
      lines[#lines + 1] = "  Complete:   " .. info.complete
    end
    if info.range then
      lines[#lines + 1] = "  Range:      yes"
    end
    if info.bang then
      lines[#lines + 1] = "  Bang:       yes"
    end
    vim.api.nvim_buf_set_lines(preview_state.buf, 0, -1, false, lines)
    vim.bo[preview_state.buf].filetype = ""
    return candidate, nil
  end

  -- Builtin command: try help
  local title, scroll_line = load_help(":" .. candidate)
  if title then
    return title, scroll_line
  end

  return nil, nil
end

--- Load environment variable value into the preview buffer.
---@param candidate string variable name (may have $ prefix)
---@return string|nil title
local function load_environment(candidate)
  local name = candidate:gsub("^%$", "")
  local value = vim.env[name]
  local lines = {
    "  $" .. name,
    "",
  }
  if value then
    lines[#lines + 1] = "  Value:"
    lines[#lines + 1] = ""
    -- Split long values (like PATH) for readability
    if name == "PATH" or name == "MANPATH" or name == "LD_LIBRARY_PATH" then
      for segment in value:gmatch("[^:]+") do
        lines[#lines + 1] = "  " .. segment
      end
    else
      lines[#lines + 1] = "  " .. value
    end
  else
    lines[#lines + 1] = "  (not set)"
  end
  vim.api.nvim_buf_set_lines(preview_state.buf, 0, -1, false, lines)
  vim.bo[preview_state.buf].filetype = ""
  return "$" .. name
end

--- Load shell command info into the preview buffer.
---@param candidate string command name
---@return string|nil title
local function load_shellcmd(candidate)
  -- Find the executable
  local path = vim.fn.exepath(candidate)
  if path == "" then
    return nil
  end
  local lines = {
    "  " .. candidate,
    "",
    "  Path:  " .. path,
  }
  -- Try to get a brief description via --help (first 20 lines)
  local ok, output = pcall(vim.fn.system, { candidate, "--help" })
  if ok and type(output) == "string" and vim.v.shell_error <= 2 then
    lines[#lines + 1] = ""
    local count = 0
    for line in output:gmatch("[^\n]+") do
      lines[#lines + 1] = line
      count = count + 1
      if count >= 25 then
        break
      end
    end
  end
  vim.api.nvim_buf_set_lines(preview_state.buf, 0, -1, false, lines)
  vim.bo[preview_state.buf].filetype = ""
  return candidate
end

--- Load autocmd event help into the preview buffer.
---@param candidate string event name
---@return string|nil title, integer|nil scroll_line
local function load_event(candidate)
  return load_help(candidate)
end

--- Load unsupported-type message into the preview buffer.
---@param candidate string
---@param expand? string the expand type, if known
local function load_unsupported(candidate, expand)
  local lines = {
    "  " .. candidate,
    "",
  }
  if expand then
    lines[#lines + 1] = "  Preview not supported for type: " .. expand
  else
    lines[#lines + 1] = "  Preview not available"
  end
  lines[#lines + 1] = ""
  lines[#lines + 1] = "  Open an issue for support:"
  lines[#lines + 1] = "  https://github.com/catgoose/wildest.nvim/issues"
  vim.api.nvim_buf_set_lines(preview_state.buf, 0, -1, false, lines)
  vim.bo[preview_state.buf].filetype = ""
end

--- Store preview config. Called from main setup when preview is configured.
---@param opts wildest.PreviewConfig
function M.setup(opts)
  opts = opts or {}
  preview_state.config = {
    enabled = opts.enabled ~= false, -- default true
    position = opts.position or "right",
    anchor = opts.anchor or "screen",
    width = opts.width or "50%",
    height = opts.height or "50%",
    border = opts.border or "single",
    max_lines = opts.max_lines or 500,
    title = opts.title ~= false, -- default true
    gap = normalize_gap(opts.gap),
    priority = opts.priority or "menu",
  }
  preview_state.enabled = preview_state.config.enabled
end

--- Returns space reserved on each edge `{top, right, bottom, left}`.
--- Always includes gutter from the top-level `gutter` config.
--- Adds preview reservations when a preview is active (screen or popup anchor).
---@return {top: integer, right: integer, bottom: integer, left: integer}
function M.reserved_space()
  local gaps_mod = require("wildest.gaps")
  local gutter = gaps_mod.gutter()
  local base = {
    top = gutter.top,
    right = gutter.right,
    bottom = gutter.bottom,
    left = gutter.left,
  }

  if not preview_state.config or not preview_state.enabled then
    return base
  end

  local cfg = preview_state.config
  local pos = cfg.position
  local gap = cfg.gap
  -- Use top-level gap as the between default; preview gap.between overrides
  local between = gap.between > 0 and gap.between or gaps_mod.gap()

  -- Popup anchor: reserve space so the popup shrinks to make room.
  -- Skip window-validity check: popup-anchor preview is drawn AFTER the
  -- renderer, so the window doesn't exist yet when this is called.
  if cfg.anchor == "popup" then
    if pos == "right" then
      base.right = base.right + parse_dim(cfg.width, vim.o.columns) + between
    elseif pos == "left" then
      base.left = base.left + parse_dim(cfg.width, vim.o.columns) + between
    elseif pos == "top" then
      local available_rows = vim.o.lines - util.reserved_chrome_rows() - 1
      base.top = base.top + parse_dim(cfg.height, available_rows) + between
    elseif pos == "bottom" then
      local available_rows = vim.o.lines - util.reserved_chrome_rows() - 1
      base.bottom = base.bottom + parse_dim(cfg.height, available_rows) + between
    end
    return base
  end

  -- Screen anchor: require visible window before reserving,
  -- unless priority="preview" (reserve unconditionally so the menu adapts).
  if cfg.anchor ~= "screen" then
    return base
  end
  if cfg.priority ~= "preview" and not vim.api.nvim_win_is_valid(preview_state.win) then
    return base
  end
  if pos == "right" then
    base.right = base.right + parse_dim(cfg.width, vim.o.columns) + between
  elseif pos == "left" then
    base.left = base.left + parse_dim(cfg.width, vim.o.columns) + between
  elseif pos == "top" then
    local available_rows = vim.o.lines - util.reserved_chrome_rows() - 1
    base.top = base.top + parse_dim(cfg.height, available_rows) + between
  elseif pos == "bottom" then
    local available_rows = vim.o.lines - util.reserved_chrome_rows() - 1
    base.bottom = base.bottom + parse_dim(cfg.height, available_rows) + between
  end
  return base
end

--- Returns the column width reserved for the preview window (including border).
--- Backward-compatible wrapper around reserved_space().
---@return integer
function M.reserved_width()
  local s = M.reserved_space()
  return s.left + s.right
end

--- Returns true when anchor mode is "screen".
---@return boolean
function M.is_screen_anchor()
  if not preview_state.config then
    return false
  end
  return preview_state.config.anchor == "screen"
end

--- Returns true when priority mode is "preview".
---@return boolean
function M.is_preview_priority()
  if not preview_state.config then
    return false
  end
  return preview_state.config.priority == "preview"
end

--- Returns true if preview is configured and enabled.
---@return boolean
function M.is_active()
  return preview_state.config ~= nil and preview_state.enabled or false
end

--- Compute the floating window position/size for the preview panel.
--- Exposed for testing as M._compute_win_config.
---@param params table
---@return table|nil {row, col, width, height}
function M._compute_win_config(params)
  local position = params.position
  local anchor = params.anchor
  local cfg_width = params.width
  local cfg_height = params.height
  local editor_cols = params.editor_cols
  local available_rows = params.available_rows
  local content_lines = params.content_lines
  local geom = params.geom
  local gap = params.gap or { top = 0, right = 0, bottom = 0, left = 0, between = 0 }
  local priority = params.priority or "menu"

  local result = {}

  if anchor == "popup" then
    if not geom then
      return nil
    end
    local has_border = geom.border and geom.border ~= "none"
    local border_size = has_border and 1 or 0

    local gaps_mod = require("wildest.gaps")
    local gutter = gaps_mod.gutter()
    -- Use top-level gap as the between default; preview gap.between overrides
    local between = gap.between > 0 and gap.between or gaps_mod.gap()

    -- When priority="preview", compute height from configured dimension
    -- instead of capping to popup height.
    local function compute_height()
      if priority == "preview" then
        return math.max(1, math.min(parse_dim(cfg_height, available_rows), content_lines))
      end
      return math.max(1, math.min(geom.height, content_lines))
    end

    if position == "right" then
      local start_col = geom.col + geom.width + 2 * border_size + between
      local avail = editor_cols - start_col - gutter.right
      if avail < MIN_PREVIEW_COLS then
        return nil
      end
      local w = math.min(parse_dim(cfg_width, editor_cols), avail)
      local h = compute_height()
      result.col = start_col
      result.row = geom.row
      result.width = math.max(1, w - 2)
      result.height = h
    elseif position == "left" then
      local avail = geom.col - between - gutter.left
      if avail < MIN_PREVIEW_COLS then
        return nil
      end
      local w = math.min(parse_dim(cfg_width, editor_cols), avail)
      local h = compute_height()
      result.col = geom.col - w - between
      result.row = geom.row
      result.width = math.max(1, w - 2)
      result.height = h
    elseif position == "top" then
      local h = parse_dim(cfg_height, available_rows)
      local avail = geom.row - 2 - between - gutter.top
      if avail < MIN_PREVIEW_ROWS then
        return nil
      end
      h = math.max(1, math.min(h, content_lines, avail))
      result.col = geom.col
      result.row = geom.row - h - 2 - between
      result.width = math.max(1, geom.width)
      result.height = h
    elseif position == "bottom" then
      local h = parse_dim(cfg_height, available_rows)
      local start_row = geom.row + geom.height + 2 * border_size + between
      local avail = available_rows - start_row - 2 - gutter.bottom
      if avail < MIN_PREVIEW_ROWS then
        return nil
      end
      h = math.max(1, math.min(h, content_lines, avail))
      result.col = geom.col
      result.row = start_row
      result.width = math.max(1, geom.width)
      result.height = h
    end
  else
    -- Screen anchor: fill entire edge of screen, inset by gutter
    local gaps_mod = require("wildest.gaps")
    local gutter = gaps_mod.gutter()
    if position == "right" then
      local w = parse_dim(cfg_width, editor_cols)
      result.row = gutter.top
      result.col = editor_cols - w - gutter.right
      result.width = math.max(1, w - 2)
      result.height = math.max(1, available_rows - gutter.top - gutter.bottom)
    elseif position == "left" then
      local w = parse_dim(cfg_width, editor_cols)
      result.row = gutter.top
      result.col = gutter.left
      result.width = math.max(1, w - 2)
      result.height = math.max(1, available_rows - gutter.top - gutter.bottom)
    elseif position == "top" then
      local h = parse_dim(cfg_height, available_rows)
      result.row = gutter.top
      result.col = gutter.left
      result.width = math.max(1, editor_cols - 2 - gutter.left - gutter.right)
      result.height = math.max(1, h - 2)
    elseif position == "bottom" then
      local h = parse_dim(cfg_height, available_rows)
      result.row = available_rows - h + 1 - gutter.bottom
      result.col = gutter.left
      result.width = math.max(1, editor_cols - 2 - gutter.left - gutter.right)
      result.height = math.max(1, h - 2)
    end
  end

  return result
end

--- Update the preview window with the selected candidate's content.
--- Called after each renderer draw.
---@param ctx table render context
---@param result table pipeline result
function M.update(ctx, result)
  if not preview_state.config or not preview_state.enabled then
    return
  end

  local candidates = result.value or {}
  local selected = ctx.selected
  local candidate = nil
  if selected >= 0 and selected < #candidates then
    candidate = candidates[selected + 1]
  end

  if candidate == nil then
    M.hide()
    return
  end

  if candidate == preview_state.last_candidate then
    return
  end
  preview_state.last_candidate = candidate

  ensure_buf()

  local cfg = preview_state.config
  local data = result.data or {}
  local expand = detect_expand(data)
  local title = nil
  local scroll_line = nil

  if expand == "file" or expand == "dir" or expand == "file_in_path" then
    title = load_file(candidate, cfg)
  elseif expand == "buffer" then
    title = load_buffer(candidate, cfg)
  elseif expand == "help" then
    title, scroll_line = load_help(candidate)
    if not title then
      load_fallback(candidate)
      title = candidate
    end
  elseif expand == "search" then
    local pattern = data.input or ""
    title, scroll_line = load_search(candidate, pattern, cfg)
  elseif expand == "option" then
    title, scroll_line = load_option(candidate)
    if not title then
      load_fallback(candidate)
      title = candidate
    end
  elseif expand == "highlight" then
    title = load_highlight(candidate)
    if not title then
      load_fallback(candidate)
      title = candidate
    end
  elseif expand == "command" then
    title, scroll_line = load_command(candidate)
    if not title then
      load_fallback(candidate)
      title = candidate
    end
  elseif expand == "environment" then
    title = load_environment(candidate)
  elseif expand == "shellcmd" then
    title = load_shellcmd(candidate)
    if not title then
      load_fallback(candidate)
      title = candidate
    end
  elseif expand == "event" then
    title, scroll_line = load_event(candidate)
    if not title then
      load_fallback(candidate)
      title = candidate
    end
  elseif data.expand and data.expand ~= "" then
    -- Known expand type without a handler — show unsupported message
    load_unsupported(candidate, data.expand)
    title = candidate
  else
    -- No expand info: try as file/directory first
    local expanded = safe_expand(candidate)
    local st = vim.uv.fs_stat(expanded)
    if st then
      title = load_file(candidate, cfg)
    else
      load_unsupported(candidate)
      title = candidate
    end
  end

  -- Position and show the preview window
  local editor_cols = vim.o.columns
  local editor_lines = vim.o.lines
  local reserved_rows = util.reserved_chrome_rows()
  local available_rows = math.max(1, editor_lines - reserved_rows - 1)
  local content_lines = vim.api.nvim_buf_line_count(preview_state.buf)

  local resolve = require("wildest.util").resolve
  local preview_ctx = { candidate = candidate, mode = ctx.cmdtype }
  local pos = M._compute_win_config({
    position = resolve(cfg.position, preview_ctx),
    anchor = cfg.anchor,
    width = resolve(cfg.width, preview_ctx),
    height = resolve(cfg.height, preview_ctx),
    editor_cols = editor_cols,
    available_rows = available_rows,
    content_lines = content_lines,
    geom = renderer_util._last_popup_geometry,
    gap = cfg.gap,
    priority = cfg.priority,
  })
  if not pos then
    return
  end

  local win_config = {
    relative = "editor",
    style = "minimal",
    border = cfg.border,
    zindex = 251,
    focusable = false,
    noautocmd = true,
    row = pos.row,
    col = pos.col,
    width = pos.width,
    height = pos.height,
  }

  if cfg.title and title then
    win_config.title = { { string.format(" %s ", title), "FloatTitle" } }
    win_config.title_pos = "center"
  end

  if vim.api.nvim_win_is_valid(preview_state.win) then
    vim.api.nvim_win_set_config(preview_state.win, win_config)
    vim.api.nvim_win_set_buf(preview_state.win, preview_state.buf)
  else
    preview_state.win = vim.api.nvim_open_win(preview_state.buf, false, win_config)
    vim.wo[preview_state.win].foldenable = false
    vim.wo[preview_state.win].wrap = false
    vim.wo[preview_state.win].cursorline = false
    vim.wo[preview_state.win].number = true
    vim.wo[preview_state.win].signcolumn = "no"
  end

  -- Scroll to tag line for help previews
  if scroll_line and vim.api.nvim_win_is_valid(preview_state.win) then
    pcall(vim.api.nvim_win_set_cursor, preview_state.win, { scroll_line, 0 })
  end
end

--- Close the preview window if open.
function M.hide()
  preview_state.last_candidate = nil
  if vim.api.nvim_win_is_valid(preview_state.win) then
    vim.api.nvim_win_close(preview_state.win, true)
  end
  preview_state.win = -1
end

--- Return current preview window geometry, or a visible=false stub.
---@return {row: number, col: number, width: number, height: number, border: any, visible: boolean}
function M.get_geometry()
  if vim.api.nvim_win_is_valid(preview_state.win) then
    local cfg = vim.api.nvim_win_get_config(preview_state.win)
    return {
      row = cfg.row,
      col = cfg.col,
      width = cfg.width,
      height = cfg.height,
      border = cfg.border,
      visible = true,
    }
  end
  return { row = 0, col = 0, width = 0, height = 0, border = nil, visible = false }
end

--- Apply adjusted geometry to the preview window.
---@param geom {row: number, col: number, width: number, height: number}
function M.apply_geometry(geom)
  if vim.api.nvim_win_is_valid(preview_state.win) then
    vim.api.nvim_win_set_config(preview_state.win, {
      relative = "editor",
      row = math.max(0, geom.row),
      col = math.max(0, geom.col),
      width = math.max(1, geom.width),
      height = math.max(1, geom.height),
    })
  end
end

--- Toggle the preview on/off.
function M.toggle()
  preview_state.enabled = not preview_state.enabled
  if not preview_state.enabled then
    M.hide()
  end
end

--- Reset preview state (for testing).
function M._reset()
  M.hide()
  preview_state.config = nil
  preview_state.enabled = false
  preview_state.last_candidate = nil
  if vim.api.nvim_buf_is_valid(preview_state.buf) then
    vim.api.nvim_buf_delete(preview_state.buf, { force = true })
  end
  preview_state.buf = -1
  preview_state.ns_id = -1
end

--- Expose detect_expand for testing.
M._detect_expand = detect_expand

--- Expose parse_dim for testing.
M._parse_dim = parse_dim

--- Expose normalize_gap for testing.
M._normalize_gap = normalize_gap

return M
