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
  renderer_util.create_accent_highlights(state)

  local renderer = setmetatable({ _state = state }, Popupmenu)
  return renderer
end

function Popupmenu:render(ctx, result)
  local state = self._state
  renderer_util.ensure_buf(state, "wildest_popupmenu")

  local candidates = result.value or {}
  local total = #candidates

  renderer_util.check_run_id(state, ctx)

  local page_start, page_end =
    renderer_util.make_page(ctx.selected, total, state.max_height, state.page)
  state.page = { page_start, page_end }

  local show_empty = total == 0 and state.empty_message
  if not show_empty and (page_start == -1 or total == 0) then
    self:hide()
    return
  end

  local row, col, editor_width, avail = renderer_util.default_position(state.offset)
  local max_w = state.max_width and renderer_util.parse_dimension(state.max_width, editor_width)
    or editor_width
  local min_w = renderer_util.parse_dimension(state.min_width, editor_width)
  local width = math.max(min_w, math.min(max_w, editor_width))

  local lines = {}
  local line_highlights = {}

  if show_empty then
    local msg = state.empty_message
    local msg_w = vim.api.nvim_strwidth(msg)
    local pad_w = width - msg_w
    if pad_w < 0 then
      pad_w = 0
    end
    local empty_line = msg .. string.rep(" ", pad_w)
    table.insert(lines, empty_line)
    table.insert(line_highlights, { spans = {}, base_hl = state.highlights.default })
  end

  local cand_lines, cand_hls = self:render_candidates(result, ctx, page_start, page_end, width)
  for i, line in ipairs(cand_lines) do
    table.insert(lines, line)
    table.insert(line_highlights, cand_hls[i])
  end

  -- Pad to min_height (or max_height when fixed_height)
  local target_height = state.fixed_height and state.max_height or state.min_height
  self:pad_to_height(lines, line_highlights, target_height, width)

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
