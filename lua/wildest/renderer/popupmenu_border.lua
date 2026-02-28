---@mod wildest.renderer.popupmenu_border Bordered Floating Popup Menu Renderer
---@brief [[
---Bordered floating popup menu renderer.
---@brief ]]

local border_theme = require("wildest.renderer.border_theme")
local renderer_util = require("wildest.renderer")

local M = {}

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

  local renderer = {}

  function renderer:render(ctx, result)
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

    local query = renderer_util.get_query(result)
    local lines = {}
    local line_highlights = {}

    -- Content lines
    for i = page_start, page_end do
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

      local line, spans = renderer_util.render_line(
        candidate,
        left_parts,
        right_parts,
        candidate_spans,
        content_width,
        base_hl
      )

      table.insert(lines, line)
      table.insert(line_highlights, { spans = spans, base_hl = base_hl })
    end

    -- Pad to fixed height
    if state.fixed_height then
      local content_count = page_end - page_start + 1
      for _ = content_count + 1, max_h do
        local pad_line = string.rep(" ", content_width)
        table.insert(lines, pad_line)
        table.insert(line_highlights, { spans = {}, base_hl = state.highlights.default })
      end
    end

    local height = #lines

    -- Neovim 0.10+ positions the border at (row, col), not the content.
    -- The bottom border lands at win_row + height + 1, so we must reserve
    -- 2 extra rows (top + bottom border) when sizing and positioning.
    local max_content = avail - 2
    if height > max_content then
      height = math.max(1, max_content)
      while #lines > height do
        table.remove(lines, #lines)
        table.remove(line_highlights, #line_highlights)
      end
    end

    vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
    renderer_util.apply_line_highlights(state.buf, state.ns_id, lines, line_highlights)

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

    -- Center horizontally when popup is narrower than available space
    local actual_col = col
    if outer_width < editor_width then
      actual_col = col + math.floor((editor_width - outer_width) / 2)
    end

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
    local title = state.title
    if type(title) == "table" then
      title = title[vim.fn.getcmdtype()] or title["default"]
    elseif type(title) == "function" then
      title = title(vim.fn.getcmdtype())
    end
    if title then
      win_config.title = { { " " .. title .. " ", state.border.native_hl } }
      win_config.title_pos = "center"
    end
    renderer_util.open_or_update_win(state, win_config)
  end

  function renderer:hide()
    renderer_util.hide_win(state)
  end

  return renderer
end

return M
