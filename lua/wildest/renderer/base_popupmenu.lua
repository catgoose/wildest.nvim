---@mod wildest.renderer.base_popupmenu Base Popupmenu Class
---@brief [[
---Base class for popupmenu-style renderers.
---Provides shared methods for candidate rendering, padding, height clamping,
---buffer flushing, title resolution, and hiding.
---@brief ]]

local renderer_util = require("wildest.renderer")

---@class wildest.BasePopupmenu
---@field _state table renderer state
local BasePopupmenu = {}
BasePopupmenu.__index = BasePopupmenu

--- Hide the popupmenu
function BasePopupmenu:hide()
  renderer_util.hide_win(self._state)
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
  local query = renderer_util.get_query(result)
  local candidates = result.value or {}
  local lines = {}
  local line_highlights = {}

  local start, finish, step
  if opts.reverse then
    start, finish, step = page_end, page_start, -1
  else
    start, finish, step = page_start, page_end, 1
  end

  for i = start, finish, step do
    local candidate = candidates[i + 1]
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

    table.insert(lines, line)
    table.insert(line_highlights, { spans = spans, base_hl = base_hl })
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

return BasePopupmenu
