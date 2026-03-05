---@mod wildest.renderer.base_popupmenu Base Popupmenu Class
---@brief [[
---Base class for popupmenu-style renderers.
---Provides shared methods for candidate rendering, padding, height clamping,
---buffer flushing, title resolution, and hiding.
---@brief ]]

local chrome = require("wildest.renderer.chrome")
local renderer_util = require("wildest.renderer")

---@class wildest.BasePopupmenu
---@field _state table renderer state
local BasePopupmenu = {}
BasePopupmenu.__index = BasePopupmenu

--- Hide the popupmenu
function BasePopupmenu:hide()
  renderer_util.hide_win(self._state)
end

--- Paginate candidates and determine whether to show the empty message.
--- Returns nil for page_start/page_end when the renderer should hide and return.
---@param ctx table render context
---@param total integer number of candidates
---@param max_height integer maximum visible lines
---@return integer|nil page_start, integer|nil page_end, boolean show_empty
function BasePopupmenu:paginate(ctx, total, max_height)
  local state = self._state
  local ncols = state.columns or 1
  local effective_page_size = max_height * ncols
  local page_start, page_end =
    renderer_util.make_page(ctx.selected, total, effective_page_size, state.page)
  state.page = { page_start, page_end }

  local show_empty = total == 0 and state.empty_message

  -- Apply empty_message_first_draw_delay: suppress empty message if within
  -- the delay window at the start of a new session.
  if
    show_empty
    and state.empty_message_first_draw_delay
    and state.empty_message_first_draw_delay > 0
  then
    local now = vim.uv.hrtime() / 1e6 -- ms
    -- Reset tracking on new session
    if ctx.session_id ~= state._delay_session_id then
      state._delay_session_id = ctx.session_id
      state._first_draw_time = nil
    end
    if not state._first_draw_time then
      state._first_draw_time = now
    end
    if (now - state._first_draw_time) < state.empty_message_first_draw_delay then
      show_empty = false
    end
  end

  if not show_empty and (page_start == -1 or total == 0) then
    self:hide()
    return nil, nil, false
  end
  return page_start, page_end, show_empty
end

--- Render the empty_message line (padded to width).
---@param width integer content width
---@return string[] lines, table[] line_highlights
function BasePopupmenu:render_empty_message(width)
  local state = self._state
  local msg = state.empty_message
  local msg_w = vim.api.nvim_strwidth(msg)
  local pad_w = math.max(0, width - msg_w)
  local line = msg .. string.rep(" ", pad_w)
  return { line }, { { spans = {}, base_hl = state.highlights.default } }
end

--- Render a single candidate into a line + highlight data.
---@param result table pipeline result
---@param ctx table render context
---@param state table renderer state
---@param query string highlight query
---@param i integer 0-indexed candidate index
---@param width integer content width for this candidate
---@return string line, table[] spans, string base_hl
function BasePopupmenu:render_one_candidate(result, ctx, state, query, i, width)
  local candidates = result.value or {}
  local raw_candidate = candidates[i + 1]
  local candidate = raw_candidate
  if result.draw then
    candidate = result.draw(result.data, raw_candidate) or raw_candidate
  end
  local is_selected = (i == ctx.selected)
  local base_hl = is_selected and state.highlights.selected or state.highlights.default
  local accent_hl = is_selected and state.highlights.selected_accent or state.highlights.accent

  local candidate_spans = renderer_util.get_candidate_spans(
    state.highlighter,
    query,
    candidate,
    accent_hl,
    state.highlights.selected_accent,
    is_selected
  )
  local left_parts, right_parts =
    renderer_util.render_components(state, ctx, result, i, is_selected)

  local line, spans =
    renderer_util.render_line(candidate, left_parts, right_parts, candidate_spans, width, base_hl)

  return line, spans, base_hl
end

--- Render candidates into lines and line_highlights arrays
---@param result table pipeline result
---@param ctx table render context
---@param page_start integer 0-indexed start
---@param page_end integer 0-indexed end (inclusive)
---@param width integer content width
---@param opts? table { reverse?: boolean }
---@return string[] lines, table[] line_highlights
function BasePopupmenu:render_candidates(result, ctx, page_start, page_end, width, opts)
  opts = opts or {}
  local state = self._state
  local ncols = state.columns or 1

  if ncols > 1 then
    return self:render_candidates_grid(result, ctx, page_start, page_end, width, opts)
  end

  local query = renderer_util.get_query(result)
  local lines = {}
  local line_highlights = {}

  local start, finish, step
  if opts.reverse then
    start, finish, step = page_end, page_start, -1
  else
    start, finish, step = page_start, page_end, 1
  end

  for i = start, finish, step do
    local line, spans, base_hl = self:render_one_candidate(result, ctx, state, query, i, width)
    table.insert(lines, line)
    table.insert(line_highlights, { spans = spans, base_hl = base_hl })
  end

  return lines, line_highlights
end

--- Render candidates in a multi-column grid layout.
---@param result table pipeline result
---@param ctx table render context
---@param page_start integer 0-indexed start
---@param page_end integer 0-indexed end (inclusive)
---@param width integer total content width
---@param opts? table { reverse?: boolean }
---@return string[] lines, table[] line_highlights
function BasePopupmenu:render_candidates_grid(result, ctx, page_start, page_end, width, opts)
  opts = opts or {}
  local state = self._state
  local ncols = state.columns or 1
  local query = renderer_util.get_query(result)
  local util = require("wildest.util")
  local col_width = math.floor(width / ncols)

  local indices = {}
  if opts.reverse then
    for i = page_end, page_start, -1 do
      indices[#indices + 1] = i
    end
  else
    for i = page_start, page_end do
      indices[#indices + 1] = i
    end
  end

  local lines = {}
  local line_highlights = {}
  local idx = 1

  while idx <= #indices do
    local row_text = ""
    local row_spans = {}
    local row_base_hl = state.highlights.default
    local byte_offset = 0

    for c = 1, ncols do
      if idx > #indices then
        -- Pad remaining columns with spaces
        local pad = width - util.strdisplaywidth(row_text)
        if pad > 0 then
          row_text = row_text .. string.rep(" ", pad)
        end
        break
      end

      local i = indices[idx]
      local cell_line, cell_spans, cell_base_hl =
        self:render_one_candidate(result, ctx, state, query, i, col_width)

      -- Truncate or pad cell to exact col_width
      local cell_display_w = util.strdisplaywidth(cell_line)
      if cell_display_w > col_width then
        -- Truncate: find byte position for col_width display chars
        local truncated = ""
        local dw = 0
        for _, ch in vim.iter(vim.fn.split(cell_line, "\\zs")):enumerate() do
          local chw = util.strdisplaywidth(ch)
          if dw + chw > col_width then
            break
          end
          truncated = truncated .. ch
          dw = dw + chw
        end
        cell_line = truncated .. string.rep(" ", col_width - util.strdisplaywidth(truncated))
      elseif cell_display_w < col_width then
        cell_line = cell_line .. string.rep(" ", col_width - cell_display_w)
      end

      -- If this cell is selected, it drives the base_hl for highlights
      if i == ctx.selected then
        row_base_hl = cell_base_hl
      end

      -- Offset cell spans to their position in the row
      for _, span in ipairs(cell_spans) do
        -- Only include spans that fall within the cell byte length
        if span[1] + span[2] <= #cell_line then
          row_spans[#row_spans + 1] = { span[1] + byte_offset, span[2], span[3] }
        end
      end

      -- Apply cell base_hl across the entire cell area (for selection background)
      if cell_base_hl ~= state.highlights.default then
        row_spans[#row_spans + 1] = { byte_offset, #cell_line, cell_base_hl }
      end

      byte_offset = byte_offset + #cell_line
      row_text = row_text .. cell_line
      idx = idx + 1
    end

    -- Pad row to full width
    local row_display_w = util.strdisplaywidth(row_text)
    if row_display_w < width then
      row_text = row_text .. string.rep(" ", width - row_display_w)
    end

    lines[#lines + 1] = row_text
    line_highlights[#line_highlights + 1] =
      { spans = row_spans, base_hl = state.highlights.default }
  end

  return lines, line_highlights
end

--- Pad lines/line_highlights to a target height
---@param lines string[]
---@param line_highlights table[]
---@param target integer target number of lines
---@param width integer content width for padding
function BasePopupmenu:pad_to_height(lines, line_highlights, target, width)
  local state = self._state
  for _ = #lines + 1, target do
    table.insert(lines, string.rep(" ", width))
    table.insert(line_highlights, { spans = {}, base_hl = state.highlights.default })
  end
end

--- Clamp lines/line_highlights to a maximum height
---@param lines string[]
---@param line_highlights table[]
---@param max integer maximum number of lines
---@return integer height actual height after clamping
function BasePopupmenu:clamp_height(lines, line_highlights, max)
  local height = #lines
  if height > max then
    height = math.max(1, max)
    while #lines > height do
      table.remove(lines)
      table.remove(line_highlights)
    end
  end
  return height
end

--- Write lines to buffer and apply highlights
---@param lines string[]
---@param line_highlights table[]
function BasePopupmenu:flush_buffer(lines, line_highlights)
  local state = self._state
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  renderer_util.apply_line_highlights(state.buf, state.ns_id, lines, line_highlights)
end

--- Resolve a title value (string, table, or function) for the current cmdtype
---@return string|nil resolved title
function BasePopupmenu:resolve_title()
  local title = self._state.title
  if type(title) == "table" then
    title = title[vim.fn.getcmdtype()] or title["default"]
  elseif type(title) == "function" then
    title = title(vim.fn.getcmdtype())
  end
  return title
end

--- Apply a resolved title to a win_config table (for bordered renderers).
---@param win_config table floating window config
function BasePopupmenu:apply_title(win_config)
  local title = self:resolve_title()
  if title then
    win_config.title = { { string.format(" %s ", title), self._state.border.native_hl } }
    win_config.title_pos = "center"
  end
end

--- Return the number of chrome components for a position (upper bound for height accounting).
---@param position "top"|"bottom"
---@return integer
function BasePopupmenu:chrome_line_count(position)
  local components = self._state[position]
  if not components then
    return 0
  end
  return #components
end

--- Render chrome lines for a position.
---@param position "top"|"bottom"
---@param ctx table render context
---@param result table pipeline result
---@param page_start integer
---@param page_end integer
---@param total integer
---@param width integer content width
---@return string[] lines, table[] line_highlights, integer count
function BasePopupmenu:render_chrome(position, ctx, result, page_start, page_end, total, width)
  local state = self._state
  local components = state[position]
  if not components or #components == 0 then
    return {}, {}, 0
  end

  local chrome_ctx = {
    width = width,
    selected = ctx.selected,
    total = total,
    page_start = page_start,
    page_end = page_end,
    result = result,
  }

  return chrome.resolve_chrome_lines(components, chrome_ctx, width, state.highlights.default)
end

return BasePopupmenu
