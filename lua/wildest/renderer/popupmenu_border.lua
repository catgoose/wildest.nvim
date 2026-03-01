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
---@param opts? table
---@field border? string|table Border style preset or 8-char array (default "single")
---@field title? string Title centered in the top border
---@field highlighter? table Highlighter for match accents
---@field left? table Left components (default { " " })
---@field right? table Right components (default { " " })
---@field max_height? integer|string Max visible lines, integer or percentage (default 16)
---@field min_height? integer Minimum visible lines (default 0)
---@field max_width? integer|string|nil Max width, integer or percentage (default nil = full width)
---@field min_width? integer|string Minimum width, integer or percentage (default 16)
---@field reverse? boolean Reverse candidate order (default false)
---@field fixed_height? boolean Pad to max_height to prevent resizing (default true)
---@field position? string Vertical placement: "top", "center", or "bottom" (default "bottom")
---@field empty_message? string Message shown when there are no results
---@field pumblend? integer Window transparency 0-100
---@field zindex? integer Floating window z-index (default 250)
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

  local candidates = result.value or {}
  local total = #candidates

  renderer_util.check_run_id(state, ctx)

  local row, col, editor_width, avail = renderer_util.default_position(state.offset)
  local editor_lines = vim.o.lines

  local max_h = renderer_util.parse_dimension(state.max_height, editor_lines)

  local page_start, page_end = renderer_util.make_page(ctx.selected, total, max_h, state.page)
  state.page = { page_start, page_end }

  if page_start == -1 or total == 0 then
    self:hide()
    return
  end

  local max_w = state.max_width and renderer_util.parse_dimension(state.max_width, editor_width)
    or editor_width
  local min_w = renderer_util.parse_dimension(state.min_width, editor_width)
  local outer_width = math.max(min_w, math.min(max_w, editor_width))
  local content_width = outer_width

  local lines, line_highlights =
    self:render_candidates(result, ctx, page_start, page_end, content_width)

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
  local title = self:resolve_title()
  if title then
    win_config.title = { { " " .. title .. " ", state.border.native_hl } }
    win_config.title_pos = "center"
  end
  renderer_util.open_or_update_win(state, win_config)
end

return M
