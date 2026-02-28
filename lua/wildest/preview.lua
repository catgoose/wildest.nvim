---@mod wildest.preview File Preview System
---@brief [[
---Floating preview window that shows file contents, buffer contents, or help
---text for the currently selected completion candidate.
---@brief ]]

local renderer_util = require("wildest.renderer")

local M = {}

---@class wildest.PreviewConfig
---@field enabled? boolean Show preview (default: true)
---@field position? string Position: "left"|"right"|"top"|"bottom" (default: "right")
---@field anchor? string Anchor: "screen"|"popup" (default: "screen")
---@field width? integer|string Panel width for left/right (default: '50%')
---@field height? integer|string Panel height for top/bottom (default: '50%')
---@field border? string|table Border style (default: 'single')
---@field max_lines? integer Max lines to read (default: 500)
---@field title? boolean Show filename in title (default: true)

local preview_state = {
  enabled = false,
  config = nil, ---@type wildest.PreviewConfig|nil
  win = -1,
  buf = -1,
  ns_id = -1,
  last_candidate = nil,
}

--- Parse a dimension config (width or height) into an integer.
---@param dim integer|string
---@param total integer
---@return integer
local function parse_dim(dim, total)
  if type(dim) == "number" then
    return math.max(1, math.min(dim, total))
  end
  if type(dim) == "string" then
    local pct = dim:match("^(%d+)%%$")
    if pct then
      return math.max(1, math.floor(tonumber(pct) / 100 * total))
    end
  end
  return math.floor(total / 2)
end

--- Determine the "expand" type from pipeline data.
--- Returns "file", "buffer", "help", or nil.
---@param data table
---@return string|nil
local function detect_expand(data)
  if data.expand then
    local e = data.expand
    if e == "file" or e == "file_in_path" or e == "dir" then
      return "file"
    end
    if e == "buffer" then
      return "buffer"
    end
    if e == "help" then
      return "help"
    end
    return nil
  end
  if data.cmd then
    local cmd = data.cmd:lower()
    if cmd == "help" or cmd == "h" then
      return "help"
    end
    if cmd == "buffer" or cmd == "b" or cmd == "sbuffer" or cmd == "sb" then
      return "buffer"
    end
    if cmd == "edit" or cmd == "e" or cmd == "split" or cmd == "sp" or cmd == "vsplit" or cmd == "vs" or cmd == "tabedit" or cmd == "tabe" then
      return "file"
    end
  end
  return nil
end

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
local function load_file(path, cfg)
  local expanded = safe_expand(path)
  if vim.fn.filereadable(expanded) ~= 1 then
    return nil
  end
  local lines = vim.fn.readfile(expanded, "", cfg.max_lines or 500)
  vim.api.nvim_buf_set_lines(preview_state.buf, 0, -1, false, lines)
  local ft = vim.filetype.match({ filename = expanded })
  if ft then
    vim.bo[preview_state.buf].filetype = ft
  else
    vim.bo[preview_state.buf].filetype = ""
  end
  return vim.fn.fnamemodify(expanded, ":t")
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
  return vim.fn.fnamemodify(name, ":t")
end

--- Load help content into the preview buffer.
---@param tag string
---@return string|nil title
local function load_help(tag)
  local help_file = vim.fn.findfile("doc/" .. tag .. ".txt", vim.o.runtimepath)
  if help_file == "" then
    -- Try to find via help tags
    local ok, result = pcall(vim.fn.execute, "silent help " .. vim.fn.fnameescape(tag), "silent!")
    if ok and result then
      -- The help command opened a window; grab the buffer contents
      local help_bufnr = vim.fn.bufnr(tag)
      if help_bufnr ~= -1 and vim.api.nvim_buf_is_valid(help_bufnr) then
        local lines = vim.api.nvim_buf_get_lines(help_bufnr, 0, 500, false)
        vim.api.nvim_buf_set_lines(preview_state.buf, 0, -1, false, lines)
        vim.bo[preview_state.buf].filetype = "help"
        return tag
      end
    end
  end
  if help_file ~= "" then
    local lines = vim.fn.readfile(help_file, "", 500)
    vim.api.nvim_buf_set_lines(preview_state.buf, 0, -1, false, lines)
    vim.bo[preview_state.buf].filetype = "help"
    return tag
  end
  return nil
end

--- Load fallback content.
---@param candidate string
local function load_fallback(candidate)
  vim.api.nvim_buf_set_lines(preview_state.buf, 0, -1, false, { candidate })
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
  }
  preview_state.enabled = preview_state.config.enabled
end

--- Returns space reserved on each edge `{top, right, bottom, left}`.
--- Only non-zero for screen anchor when the preview window is visible.
---@return {top: integer, right: integer, bottom: integer, left: integer}
function M.reserved_space()
  local zero = { top = 0, right = 0, bottom = 0, left = 0 }
  if not preview_state.config or not preview_state.enabled then
    return zero
  end
  if preview_state.config.anchor ~= "screen" then
    return zero
  end
  if not vim.api.nvim_win_is_valid(preview_state.win) then
    return zero
  end

  local cfg = preview_state.config
  local pos = cfg.position
  if pos == "right" then
    return { top = 0, right = parse_dim(cfg.width, vim.o.columns), bottom = 0, left = 0 }
  elseif pos == "left" then
    return { top = 0, right = 0, bottom = 0, left = parse_dim(cfg.width, vim.o.columns) }
  elseif pos == "top" then
    local height = vim.o.lines
    local reserved = vim.o.cmdheight + (vim.o.laststatus > 0 and 1 or 0)
    local available_rows = height - reserved - 1
    return { top = parse_dim(cfg.height, available_rows), right = 0, bottom = 0, left = 0 }
  elseif pos == "bottom" then
    local height = vim.o.lines
    local reserved = vim.o.cmdheight + (vim.o.laststatus > 0 and 1 or 0)
    local available_rows = height - reserved - 1
    return { top = 0, right = 0, bottom = parse_dim(cfg.height, available_rows), left = 0 }
  end
  return zero
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

--- Returns true if preview is configured and enabled.
---@return boolean
function M.is_active()
  return preview_state.config ~= nil and preview_state.enabled
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

  if expand == "file" then
    title = load_file(candidate, cfg)
  elseif expand == "buffer" then
    title = load_buffer(candidate, cfg)
  elseif expand == "help" then
    title = load_help(candidate)
  else
    -- Heuristic: try as file first
    local expanded = safe_expand(candidate)
    if vim.fn.filereadable(expanded) == 1 then
      title = load_file(candidate, cfg)
    else
      load_fallback(candidate)
      title = candidate
    end
  end

  -- Position and show the preview window
  local editor_cols = vim.o.columns
  local editor_lines = vim.o.lines
  local cmdheight = vim.o.cmdheight
  local reserved_rows = cmdheight + (vim.o.laststatus > 0 and 1 or 0)
  local available_rows = math.max(1, editor_lines - reserved_rows - 1)
  local position = cfg.position
  local content_lines = vim.api.nvim_buf_line_count(preview_state.buf)

  local win_config = {
    relative = "editor",
    style = "minimal",
    border = cfg.border,
    zindex = 251,
    focusable = false,
    noautocmd = true,
  }

  if cfg.anchor == "popup" then
    -- Popup anchor: position adjacent to popup, content-aware sizing
    local geom = renderer_util._last_popup_geometry
    if not geom then
      return
    end
    local has_border = geom.border and geom.border ~= "none"
    local border_size = has_border and 1 or 0

    if position == "right" then
      local w = parse_dim(cfg.width, editor_cols)
      local h = math.max(1, math.min(geom.height, content_lines))
      win_config.col = geom.col + geom.width + border_size
      win_config.row = geom.row
      win_config.width = math.max(1, w - 2)
      win_config.height = h
    elseif position == "left" then
      local w = parse_dim(cfg.width, editor_cols)
      local h = math.max(1, math.min(geom.height, content_lines))
      win_config.col = geom.col - w - border_size
      win_config.row = geom.row
      win_config.width = math.max(1, w - 2)
      win_config.height = h
    elseif position == "top" then
      local h = parse_dim(cfg.height, available_rows)
      h = math.max(1, math.min(h, content_lines))
      win_config.col = geom.col
      win_config.row = geom.row - h - border_size - 1
      win_config.width = math.max(1, geom.width)
      win_config.height = h
    elseif position == "bottom" then
      local h = parse_dim(cfg.height, available_rows)
      h = math.max(1, math.min(h, content_lines))
      win_config.col = geom.col
      win_config.row = geom.row + geom.height + border_size + 1
      win_config.width = math.max(1, geom.width)
      win_config.height = h
    end
  else
    -- Screen anchor: fill entire edge of screen
    if position == "right" then
      local w = parse_dim(cfg.width, editor_cols)
      win_config.row = 0
      win_config.col = editor_cols - w
      win_config.width = math.max(1, w - 2)
      win_config.height = available_rows
    elseif position == "left" then
      local w = parse_dim(cfg.width, editor_cols)
      win_config.row = 0
      win_config.col = 0
      win_config.width = math.max(1, w - 2)
      win_config.height = available_rows
    elseif position == "top" then
      local h = parse_dim(cfg.height, available_rows)
      win_config.row = 0
      win_config.col = 0
      win_config.width = math.max(1, editor_cols - 2)
      win_config.height = h
    elseif position == "bottom" then
      local h = parse_dim(cfg.height, available_rows)
      win_config.row = available_rows - h
      win_config.col = 0
      win_config.width = math.max(1, editor_cols - 2)
      win_config.height = h
    end
  end

  if cfg.title and title then
    win_config.title = { { " " .. title .. " ", "FloatTitle" } }
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
end

--- Close the preview window if open.
function M.hide()
  preview_state.last_candidate = nil
  if vim.api.nvim_win_is_valid(preview_state.win) then
    vim.api.nvim_win_close(preview_state.win, true)
  end
  preview_state.win = -1
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

return M
