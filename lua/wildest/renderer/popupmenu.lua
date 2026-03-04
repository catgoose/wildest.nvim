---@mod wildest.renderer.popupmenu Floating Popup Menu Renderer
---@brief [[
---Floating popup menu renderer.
---@brief ]]

local BasePopupmenu = require("wildest.renderer.base_popupmenu")
local renderer_util = require("wildest.renderer")

local M = {}

---@class wildest.Popupmenu : wildest.BasePopupmenu
local Popupmenu = setmetatable({}, { __index = BasePopupmenu })
Popupmenu.__index = Popupmenu

--- Create a new popupmenu renderer
---@param opts? wildest.PopupmenuOpts
---@return table renderer object
function M.new(opts)
  opts = opts or {}

  local state = renderer_util.create_base_state(opts)
  state.empty_message = opts.empty_message
  state.empty_message_first_draw_delay = opts.empty_message_first_draw_delay
  renderer_util.create_accent_highlights(state)

  local renderer = setmetatable({ _state = state }, Popupmenu)
  return renderer
end

function Popupmenu:render(ctx, result)
  local state = self._state
  renderer_util.ensure_buf(state, "wildest_popupmenu")

  local total = #(result.value or {})

  renderer_util.check_run_id(state, ctx)

  -- Reserve space for chrome lines
  local chrome_lines = self:chrome_line_count("top") + self:chrome_line_count("bottom")
  local content_max_h = math.max(1, state.max_height - chrome_lines)

  local page_start, page_end, show_empty = self:paginate(ctx, total, content_max_h)
  if not page_start then
    return
  end

  local row, col, editor_width, avail = renderer_util.default_position(state.offset)
  local width = renderer_util.calculate_width(state.max_width, state.min_width, editor_width)

  -- Top chrome
  local top_lines, top_hls =
    self:render_chrome("top", ctx, result, page_start, page_end, total, width)

  local lines = {}
  local line_highlights = {}

  for i, line in ipairs(top_lines) do
    lines[#lines + 1] = line
    line_highlights[#line_highlights + 1] = top_hls[i]
  end

  if show_empty then
    local empty_lines, empty_hls = self:render_empty_message(width)
    for i, line in ipairs(empty_lines) do
      lines[#lines + 1] = line
      line_highlights[#line_highlights + 1] = empty_hls[i]
    end
  else
    local cand_lines, cand_hls = self:render_candidates(result, ctx, page_start, page_end, width)
    for i, line in ipairs(cand_lines) do
      lines[#lines + 1] = line
      line_highlights[#line_highlights + 1] = cand_hls[i]
    end
  end

  -- Pad candidate area to target height (chrome excluded from padding target)
  local content_target = state.fixed_height and content_max_h or state.min_height
  local actual_top = #top_lines
  self:pad_to_height(lines, line_highlights, actual_top + content_target, width)

  -- Bottom chrome
  local bottom_lines, bottom_hls =
    self:render_chrome("bottom", ctx, result, page_start, page_end, total, width)
  for i, line in ipairs(bottom_lines) do
    lines[#lines + 1] = line
    line_highlights[#line_highlights + 1] = bottom_hls[i]
  end

  -- Clamp height to available space (accounts for preview reserved space)
  local height = self:clamp_height(lines, line_highlights, avail)

  self:flush_buffer(lines, line_highlights)

  local actual_col = renderer_util.center_col(col, width, editor_width)

  -- +1 aligns the borderless popup's bottom with the bordered renderer's
  -- bottom border, sitting directly above the statusline.
  renderer_util.open_or_update_win(state, {
    relative = "editor",
    row = math.max(0, row - height + 1),
    col = actual_col,
    width = width,
    height = height,
    style = "minimal",
    border = "none",
    zindex = state.zindex,
    focusable = false,
    noautocmd = true,
  })
end

return M
