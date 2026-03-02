---@mod wildest.renderer.popupmenu_border Bordered Floating Popup Menu Renderer
---@brief [[
---Bordered floating popup menu renderer.
---@brief ]]

local BasePopupmenu = require("wildest.renderer.base_popupmenu")
local border_theme = require("wildest.renderer.border_theme")
local renderer_util = require("wildest.renderer")

local M = {}

---@class wildest.PopupmenuBorder : wildest.BasePopupmenu
local PopupmenuBorder = setmetatable({}, { __index = BasePopupmenu })
PopupmenuBorder.__index = PopupmenuBorder

--- Create a bordered popupmenu renderer
---@param opts? wildest.PopupmenuBorderOpts
---@return table renderer object
function M.new(opts)
  opts = opts or {}

  local border_info = border_theme.apply({
    border = opts.border or "single",
    highlights = opts.highlights,
    content_hl = opts.hl or "WildestDefault",
  })

  local state = renderer_util.create_base_state(opts)
  state.highlights.border = border_info.border_hl
  state.highlights.bottom_border = border_info.bottom_border_hl
  state.empty_message = opts.empty_message
  state.title = opts.title
  state.position = opts.position or "bottom"
  state.border = border_info
  renderer_util.create_accent_highlights(state)

  local renderer = setmetatable({ _state = state }, PopupmenuBorder)
  return renderer
end

function PopupmenuBorder:render(ctx, result)
  local state = self._state
  renderer_util.ensure_buf(state, "wildest_popupmenu_border")

  local total = #(result.value or {})

  renderer_util.check_run_id(state, ctx)

  local row, col, editor_width, avail = renderer_util.default_position(state.offset)
  local max_h = renderer_util.parse_dimension(state.max_height, vim.o.lines)

  local page_start, page_end, show_empty = self:paginate(ctx, total, max_h)
  if not page_start then
    return
  end

  local outer_width = renderer_util.calculate_width(state.max_width, state.min_width, editor_width)
  local content_width = outer_width

  local lines, line_highlights
  if show_empty then
    lines, line_highlights = self:render_empty_message(content_width)
  else
    lines, line_highlights =
      self:render_candidates(result, ctx, page_start, page_end, content_width)
  end

  -- Pad to fixed height
  if state.fixed_height then
    self:pad_to_height(lines, line_highlights, max_h, content_width)
  end

  -- Neovim 0.10+ positions the border at (row, col), not the content.
  -- The bottom border lands at win_row + height + 1, so we must reserve
  -- 2 extra rows (top + bottom border) when sizing and positioning.
  local max_content = avail - 2
  local height = self:clamp_height(lines, line_highlights, max_content)

  self:flush_buffer(lines, line_highlights)

  local win_row
  if state.position == "top" then
    win_row = 0
  elseif state.position == "center" then
    win_row = math.max(0, math.floor((row - height) / 2))
  else
    -- -1 so the top border sits above the content and the bottom border
    -- stays above the statusline (border is drawn outside the content area
    -- but positioned at win_row in Neovim 0.10+).
    win_row = math.max(0, row - height - 1)
  end

  local actual_col = renderer_util.center_col(col, outer_width, editor_width)

  local win_config = {
    relative = "editor",
    row = win_row,
    col = actual_col,
    width = outer_width,
    height = height,
    style = "minimal",
    border = state.border.native_border,
    zindex = state.zindex,
    focusable = false,
    noautocmd = true,
  }
  self:apply_title(win_config)
  renderer_util.open_or_update_win(state, win_config)
end

return M
