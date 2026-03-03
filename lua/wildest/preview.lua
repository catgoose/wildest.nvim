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
local function load_file(path, cfg)
  local expanded = safe_expand(path)
  if not vim.uv.fs_stat(expanded) then
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
  local title = vim.fs.basename(expanded)
  return title
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

--- Load help content into the preview buffer.
---@param tag string
---@return string|nil title
local function load_help(tag)
  -- Try direct file lookup first
  local rtp = vim.o.runtimepath ---@type string
  local help_file = vim.fn.findfile(string.format("doc/%s.txt", tag), rtp)
  if help_file ~= "" then
    local lines = vim.fn.readfile(help_file, "", 500)
    vim.api.nvim_buf_set_lines(preview_state.buf, 0, -1, false, lines)
    vim.bo[preview_state.buf].filetype = "help"
    return tag
  end
  -- Fall back to taglist to locate the help file without opening a window
  local ok, tags = pcall(vim.fn.taglist, string.format("^%s$", vim.fn.escape(tag, "\\")))
  if ok and type(tags) == "table" then
    for _, entry in ipairs(tags) do
      local fname = entry.filename
      if fname and vim.uv.fs_stat(fname) then
        local lines = vim.fn.readfile(fname, "", 500)
        vim.api.nvim_buf_set_lines(preview_state.buf, 0, -1, false, lines)
        vim.bo[preview_state.buf].filetype = "help"
        return tag
      end
    end
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
    gap = normalize_gap(opts.gap),
    priority = opts.priority or "menu",
  }
  preview_state.enabled = preview_state.config.enabled
end

--- Returns space reserved on each edge `{top, right, bottom, left}`.
--- Non-zero for screen anchor (when window visible) and popup anchor
--- (so popups shrink to fit the preview).
---@return {top: integer, right: integer, bottom: integer, left: integer}
function M.reserved_space()
  local zero = { top = 0, right = 0, bottom = 0, left = 0 }
  if not preview_state.config or not preview_state.enabled then
    return zero
  end

  local cfg = preview_state.config
  local pos = cfg.position
  local gap = cfg.gap

  -- Popup anchor: reserve space so the popup shrinks to make room.
  -- Skip window-validity check: popup-anchor preview is drawn AFTER the
  -- renderer, so the window doesn't exist yet when this is called.
  if cfg.anchor == "popup" then
    if pos == "right" then
      return { top = gap.top, right = parse_dim(cfg.width, vim.o.columns) + gap.right + gap.between, bottom = gap.bottom, left = gap.left }
    elseif pos == "left" then
      return { top = gap.top, right = gap.right, bottom = gap.bottom, left = parse_dim(cfg.width, vim.o.columns) + gap.left + gap.between }
    elseif pos == "top" then
      local available_rows = vim.o.lines - util.reserved_chrome_rows() - 1
      return { top = parse_dim(cfg.height, available_rows) + gap.top + gap.between, right = gap.right, bottom = gap.bottom, left = gap.left }
    elseif pos == "bottom" then
      local available_rows = vim.o.lines - util.reserved_chrome_rows() - 1
      return { top = gap.top, right = gap.right, bottom = parse_dim(cfg.height, available_rows) + gap.bottom + gap.between, left = gap.left }
    end
  end

  -- Screen anchor: require visible window before reserving,
  -- unless priority="preview" (reserve unconditionally so the menu adapts).
  if cfg.anchor ~= "screen" then
    return zero
  end
  if cfg.priority ~= "preview" and not vim.api.nvim_win_is_valid(preview_state.win) then
    return zero
  end
  if pos == "right" then
    return { top = gap.top, right = parse_dim(cfg.width, vim.o.columns) + gap.right, bottom = gap.bottom, left = gap.left }
  elseif pos == "left" then
    return { top = gap.top, right = gap.right, bottom = gap.bottom, left = parse_dim(cfg.width, vim.o.columns) + gap.left }
  elseif pos == "top" then
    local available_rows = vim.o.lines - util.reserved_chrome_rows() - 1
    return { top = parse_dim(cfg.height, available_rows) + gap.top, right = gap.right, bottom = gap.bottom, left = gap.left }
  elseif pos == "bottom" then
    local available_rows = vim.o.lines - util.reserved_chrome_rows() - 1
    return { top = gap.top, right = gap.right, bottom = parse_dim(cfg.height, available_rows) + gap.bottom, left = gap.left }
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

    -- When priority="preview", compute height from configured dimension
    -- instead of capping to popup height.
    local function compute_height()
      if priority == "preview" then
        return math.max(1, math.min(parse_dim(cfg_height, available_rows), content_lines))
      end
      return math.max(1, math.min(geom.height, content_lines))
    end

    if position == "right" then
      local start_col = geom.col + geom.width + border_size + gap.between
      local avail = editor_cols - start_col - gap.right
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
      local avail = geom.col - border_size - gap.between - gap.left
      if avail < MIN_PREVIEW_COLS then
        return nil
      end
      local w = math.min(parse_dim(cfg_width, editor_cols), avail)
      local h = compute_height()
      result.col = geom.col - w - border_size - gap.between
      result.row = geom.row
      result.width = math.max(1, w - 2)
      result.height = h
    elseif position == "top" then
      local h = parse_dim(cfg_height, available_rows)
      local avail = geom.row - 2 - gap.between - gap.top
      if avail < MIN_PREVIEW_ROWS then
        return nil
      end
      h = math.max(1, math.min(h, content_lines, avail))
      result.col = geom.col
      result.row = geom.row - h - 2 - gap.between
      result.width = math.max(1, geom.width)
      result.height = h
    elseif position == "bottom" then
      local h = parse_dim(cfg_height, available_rows)
      local start_row = geom.row + geom.height + border_size + 1 + gap.between
      local avail = available_rows - start_row - 2 - gap.bottom
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
    -- Screen anchor: fill entire edge of screen, inset by edge gaps
    if position == "right" then
      local w = parse_dim(cfg_width, editor_cols)
      result.row = gap.top
      result.col = editor_cols - w - gap.right
      result.width = math.max(1, w - 2)
      result.height = math.max(1, available_rows - gap.top - gap.bottom)
    elseif position == "left" then
      local w = parse_dim(cfg_width, editor_cols)
      result.row = gap.top
      result.col = gap.left
      result.width = math.max(1, w - 2)
      result.height = math.max(1, available_rows - gap.top - gap.bottom)
    elseif position == "top" then
      local h = parse_dim(cfg_height, available_rows)
      result.row = gap.top
      result.col = gap.left
      result.width = math.max(1, editor_cols - 2 - gap.left - gap.right)
      result.height = math.max(1, h - 2)
    elseif position == "bottom" then
      local h = parse_dim(cfg_height, available_rows)
      result.row = available_rows - h + 1 - gap.bottom
      result.col = gap.left
      result.width = math.max(1, editor_cols - 2 - gap.left - gap.right)
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

  if expand == "file" then
    title = load_file(candidate, cfg)
  elseif expand == "buffer" then
    title = load_buffer(candidate, cfg)
  elseif expand == "help" then
    title = load_help(candidate)
  else
    -- Heuristic: try as file first
    local expanded = safe_expand(candidate)
    if vim.uv.fs_stat(expanded) then
      title = load_file(candidate, cfg)
    else
      load_fallback(candidate)
      title = candidate
    end
  end

  -- Position and show the preview window
  local editor_cols = vim.o.columns
  local editor_lines = vim.o.lines
  local reserved_rows = util.reserved_chrome_rows()
  local available_rows = math.max(1, editor_lines - reserved_rows - 1)
  local content_lines = vim.api.nvim_buf_line_count(preview_state.buf)

  local pos = M._compute_win_config({
    position = cfg.position,
    anchor = cfg.anchor,
    width = cfg.width,
    height = cfg.height,
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
