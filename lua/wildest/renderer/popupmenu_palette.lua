---@mod wildest.renderer.popupmenu_palette Centered Palette-Style Popup Renderer
---@brief [[
---Centered palette-style popup renderer.
---@brief ]]

local BasePopupmenu = require("wildest.renderer.base_popupmenu")
local border_theme = require("wildest.renderer.border_theme")
local hl_mod = require("wildest.highlight")
local renderer_util = require("wildest.renderer")
local util = require("wildest.util")

local M = {}

---@class wildest.PopupmenuPalette : wildest.BasePopupmenu
local PopupmenuPalette = setmetatable({}, { __index = BasePopupmenu })
PopupmenuPalette.__index = PopupmenuPalette

--- Create a palette-themed popupmenu renderer
---@param opts? table
---@field border? string|table Border style preset or 8-char array (default "rounded")
---@field title? string Title centered in the top border
---@field prompt_prefix? string Prefix shown before cmdline input (default " : ")
---@field prompt_position? string Prompt placement: "top" or "bottom" (default "top")
---@field highlighter? table Highlighter for match accents
---@field left? table Left components (default { " " })
---@field right? table Right components (default { " " })
---@field max_height? string|integer Max height, percentage or integer (default "75%")
---@field min_height? integer Minimum height (default 0)
---@field max_width? string|integer Max width, percentage or integer (default "75%")
---@field min_width? integer|string Minimum width (default 30)
---@field margin? string|integer Horizontal margin: "auto", percentage, or integer (default "auto")
---@field reverse? boolean Reverse candidate order (default false)
---@field fixed_height? boolean Pad to max_height to prevent resizing (default true)
---@field empty_message? string Message shown when there are no results
---@field pumblend? integer Window transparency 0-100
---@field zindex? integer Floating window z-index (default 250)
---@return table renderer object
function M.new(opts)
  opts = opts or {}

  local border_info = border_theme.apply({
    border = opts.border or "rounded",
    highlights = opts.highlights,
    content_hl = opts.hl or "WildestDefault",
  })

  local prompt_border = opts.prompt_border
    or { border_info.border_chars[4], "─", border_info.border_chars[5] }
  local prompt_position = opts.prompt_position or "top"

  local state = renderer_util.create_base_state(opts, {
    max_height = "75%",
    max_width = "75%",
    min_width = 30,
  })
  state.highlights.border = border_info.border_hl
  state.highlights.bottom_border = border_info.bottom_border_hl
  state.highlights.prompt = (opts.highlights and opts.highlights.prompt) or "WildestPrompt"
  state.highlights.prompt_cursor = (opts.highlights and opts.highlights.prompt_cursor)
    or "WildestPromptCursor"
  state.margin = opts.margin or "auto"
  state.title = opts.title
  state.prompt_prefix = opts.prompt_prefix or function(cmdtype)
    return " " .. cmdtype
  end
  state.empty_message = opts.empty_message
  state.border = border_info
  state.prompt_border = prompt_border
  state.prompt_position = prompt_position

  -- Separator highlight: border fg on prompt/content bg so it blends with the content area
  local border_def = vim.api.nvim_get_hl(0, { name = state.highlights.border, link = false })
  state.highlights.separator =
    hl_mod.make_hl("WildestSeparator", state.highlights.prompt, { fg = border_def.fg })

  renderer_util.create_accent_highlights(state)

  local renderer = setmetatable({ _state = state }, PopupmenuPalette)
  return renderer
end

--- Build the prompt line showing the current cmdline with cursor
---@param self wildest.PopupmenuPalette
---@param content_width integer
---@return string line, table[] spans
local function build_prompt_line(self, content_width)
  local state = self._state
  local cmdline = vim.fn.getcmdline() or ""
  local cmdpos = vim.fn.getcmdpos() or (#cmdline + 1)
  local cmdtype = vim.fn.getcmdtype() or ":"

  local prompt_prefix = state.prompt_prefix
  if type(prompt_prefix) == "table" then
    prompt_prefix = prompt_prefix[cmdtype] or prompt_prefix["default"] or (" " .. cmdtype)
  elseif type(prompt_prefix) == "function" then
    prompt_prefix = prompt_prefix(cmdtype)
  end
  local prefix_width = util.strdisplaywidth(prompt_prefix)
  local avail = content_width - prefix_width

  local display = cmdline
  if util.strdisplaywidth(display) > avail then
    display = util.truncate(display, avail, "")
  end

  local display_w = util.strdisplaywidth(display)
  local pad = ""
  if display_w + prefix_width < content_width then
    pad = string.rep(" ", content_width - display_w - prefix_width)
  end

  local line = prompt_prefix .. display .. pad

  local spans = {}
  if cmdpos >= 1 and cmdpos <= #cmdline + 1 then
    local cursor_byte = #prompt_prefix + cmdpos - 1
    local cursor_len = 1
    if cmdpos <= #cmdline then
      cursor_len = #cmdline:sub(cmdpos, cmdpos)
    end
    if cursor_byte < #line then
      table.insert(spans, { cursor_byte, cursor_len, state.highlights.prompt_cursor })
    end
  end

  return line, spans
end

function PopupmenuPalette:render(ctx, result)
  local state = self._state
  renderer_util.ensure_buf(state, "wildest_popupmenu_palette")

  local candidates = result.value or {}
  local total = #candidates

  renderer_util.check_run_id(state, ctx)

  local preview = require("wildest.preview")
  local space = preview.reserved_space()
  local editor_lines = vim.o.lines
  local editor_cols = vim.o.columns - space.left - space.right

  local max_w = renderer_util.parse_dimension(state.max_width, editor_cols)
  local min_w = renderer_util.parse_dimension(state.min_width, editor_cols)
  local outer_width = math.max(min_w, math.min(max_w, editor_cols))

  local max_h = renderer_util.parse_dimension(state.max_height, editor_lines)
  local chrome_lines = 2 -- prompt + separator
  local content_max_h = math.max(1, max_h - chrome_lines)

  local page_start, page_end =
    renderer_util.make_page(ctx.selected, total, content_max_h, state.page)
  state.page = { page_start, page_end }

  local show_empty = total == 0 and state.empty_message
  if not show_empty and (page_start == -1 or total == 0) then
    self:hide()
    return
  end

  local content_width = outer_width

  local lines = {}
  local line_highlights = {}

  -- Prompt at top
  if state.prompt_position == "top" then
    local prompt_line, prompt_spans = build_prompt_line(self, content_width)
    table.insert(lines, prompt_line)
    table.insert(line_highlights, { spans = prompt_spans, base_hl = state.highlights.prompt })

    local separator = string.rep("─", content_width)
    table.insert(lines, separator)
    table.insert(line_highlights, { spans = {}, base_hl = state.highlights.separator })
  end

  -- Content lines
  local content_count = 0
  if show_empty then
    local msg = state.empty_message
    local msg_w = util.strdisplaywidth(msg)
    local pad_w = content_width - msg_w
    if pad_w < 0 then
      pad_w = 0
    end
    local empty_line = msg .. string.rep(" ", pad_w)
    table.insert(lines, empty_line)
    table.insert(line_highlights, { spans = {}, base_hl = state.highlights.default })
    content_count = 1
  else
    local cand_lines, cand_hls = self:render_candidates(
      result,
      ctx,
      page_start,
      page_end,
      content_width,
      { reverse = state.reverse }
    )
    for i, line in ipairs(cand_lines) do
      table.insert(lines, line)
      table.insert(line_highlights, cand_hls[i])
    end
    content_count = page_end - page_start + 1
  end

  -- Pad content area to target height
  local min_content_h = math.max(0, (state.min_height or 0) - chrome_lines)
  local target_content_h = state.fixed_height and content_max_h or min_content_h
  self:pad_to_height(
    lines,
    line_highlights,
    #lines + (target_content_h - content_count),
    content_width
  )

  -- Prompt at bottom
  if state.prompt_position == "bottom" then
    local separator = string.rep("─", content_width)
    table.insert(lines, separator)
    table.insert(line_highlights, { spans = {}, base_hl = state.highlights.separator })

    local prompt_line, prompt_spans = build_prompt_line(self, content_width)
    table.insert(lines, prompt_line)
    table.insert(line_highlights, { spans = prompt_spans, base_hl = state.highlights.prompt })
  end

  -- Account for border rows and reserved lines (statusline + cmdline) so
  -- the bottom border never overlaps the statusline.
  local border_rows = 2 -- top + bottom border
  local reserved = math.max(vim.o.cmdheight, 1) + (vim.o.laststatus > 0 and 1 or 0)
  local usable_lines = editor_lines - reserved - space.top - space.bottom
  local max_content_height = usable_lines - border_rows
  local height = self:clamp_height(lines, line_highlights, max_content_height)

  -- Position: centered within usable area
  local margin_left = renderer_util.parse_margin(state.margin, editor_cols, outer_width)
    + space.left
  local total_with_border = height + border_rows
  local margin_top = math.max(
    0,
    math.floor((usable_lines - total_with_border) / 2) - (state.offset or 0)
  ) + space.top

  self:flush_buffer(lines, line_highlights)

  local win_config = {
    relative = "editor",
    row = margin_top,
    col = margin_left,
    width = outer_width,
    height = height,
    style = "minimal",
    border = state.border.native_border,
    zindex = state.zindex,
    focusable = false,
    noautocmd = true,
  }
  local title = self:resolve_title()
  if title then
    win_config.title = { { " " .. title .. " ", state.border.native_hl } }
    win_config.title_pos = "center"
  end
  renderer_util.open_or_update_win(state, win_config)
end

return M
