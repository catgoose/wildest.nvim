---@mod wildest.renderer.popupmenu Floating Popup Menu Renderer
---@brief [[
---Floating popup menu renderer.
---@brief ]]

local renderer_util = require("wildest.renderer")

local M = {}

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

  local renderer = {}

  function renderer:render(ctx, result)
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

    local query = renderer_util.get_query(result)
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
        width,
        base_hl
      )

      table.insert(lines, line)
      table.insert(line_highlights, { spans = spans, base_hl = base_hl })
    end

    -- Pad to min_height (or max_height when fixed_height)
    local height = #lines
    local target_height = state.fixed_height and state.max_height or state.min_height
    if height < target_height then
      for _ = height + 1, target_height do
        table.insert(lines, string.rep(" ", width))
        table.insert(line_highlights, { spans = {}, base_hl = state.highlights.default })
      end
      height = target_height
    end

    -- Clamp height to available space (accounts for preview reserved space)
    if height > avail then
      height = math.max(1, avail)
      while #lines > height do
        table.remove(lines)
        table.remove(line_highlights)
      end
    end

    vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
    renderer_util.apply_line_highlights(state.buf, state.ns_id, lines, line_highlights)

    -- Center horizontally when popup is narrower than available space
    local actual_col = col
    if width < editor_width then
      actual_col = col + math.floor((editor_width - width) / 2)
    end

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

  function renderer:hide()
    renderer_util.hide_win(state)
  end

  return renderer
end

return M
