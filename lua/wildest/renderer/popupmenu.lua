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
---@param opts? table
---@field highlighter? table Highlighter for match accents
---@field left? table Left components (default { " " })
---@field right? table Right components (default { " " })
---@field max_height? integer Maximum number of visible lines (default 16)
---@field min_height? integer Minimum number of visible lines (default 0)
---@field max_width? integer|string|nil Maximum width, integer or percentage (default nil = full width)
---@field min_width? integer|string Minimum width, integer or percentage (default 16)
---@field reverse? boolean Reverse candidate order (default false)
---@field fixed_height? boolean Pad to max_height to prevent resizing (default true)
---@field empty_message? string Message shown when there are no results
---@field pumblend? integer Window transparency 0-100
---@field zindex? integer Floating window z-index (default 250)
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
