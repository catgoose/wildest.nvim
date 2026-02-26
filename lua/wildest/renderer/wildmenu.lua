---@mod wildest.renderer.wildmenu Horizontal Wildmenu Renderer
---@brief [[
---Horizontal wildmenu renderer.
---@brief ]]

local cache_mod = require("wildest.cache")
local hl_mod = require("wildest.highlight")
local renderer_util = require("wildest.renderer")
local util = require("wildest.util")

local M = {}

--- Compute which candidates are visible in the horizontal wildmenu
---@param selected integer
---@param total integer
---@param candidates string[]
---@param avail_width integer
---@param sep_width integer
---@param current_page table
---@return integer start, integer finish
local function make_page(selected, total, candidates, avail_width, sep_width, current_page)
  if total == 0 then
    return -1, -1
  end

  if selected == -1 then
    -- Show as many as fit from the start
    local width = 0
    local finish = -1
    for i = 0, total - 1 do
      local cw = util.strdisplaywidth(candidates[i + 1])
      local needed = cw + (finish >= 0 and sep_width or 0)
      if width + needed > avail_width then
        break
      end
      width = width + needed
      finish = i
    end
    if finish == -1 then
      finish = 0
    end
    return 0, finish
  end

  -- Try to keep selected visible, expanding around it
  local start = selected
  local finish = selected
  local width = util.strdisplaywidth(candidates[selected + 1])

  -- Expand left
  while start > 0 do
    local cw = util.strdisplaywidth(candidates[start]) + sep_width
    if width + cw > avail_width then
      break
    end
    start = start - 1
    width = width + cw
  end

  -- Expand right
  while finish < total - 1 do
    local cw = util.strdisplaywidth(candidates[finish + 2]) + sep_width
    if width + cw > avail_width then
      break
    end
    finish = finish + 1
    width = width + cw
  end

  return start, finish
end

--- Create a new wildmenu renderer
---@param opts? table
---@return table renderer object
function M.new(opts)
  opts = opts or {}

  local state = {
    highlights = {
      default = opts.hl or "StatusLine",
      selected = opts.selected_hl or "WildMenu",
      accent = nil,
      selected_accent = nil,
    },
    separator = opts.separator or "  ",
    ellipsis = opts.ellipsis or "...",
    left = opts.left or {},
    right = opts.right or {},
    highlighter = opts.highlighter,
    zindex = opts.zindex or 250,

    -- Runtime state
    buf = -1,
    win = -1,
    ns_id = -1,
    page = { -1, -1 },
    run_id = -1,
    draw_cache = cache_mod.dict_cache(),
  }

  -- Create accent highlights
  state.highlights.accent =
    hl_mod.hl_with_attr("WildestWildAccent", state.highlights.default, "underline", "bold")
  state.highlights.selected_accent =
    hl_mod.hl_with_attr("WildestWildSelectedAccent", state.highlights.selected, "underline", "bold")

  local renderer = {}

  --- Render the wildmenu
  function renderer:render(ctx, result)
    renderer_util.ensure_buf(state, "wildest_wildmenu")

    local candidates = result.value or {}
    local total = #candidates

    renderer_util.check_run_id(state, ctx)

    if total == 0 then
      self:hide()
      return
    end

    local editor_width = vim.o.columns
    local sep_width = util.strdisplaywidth(state.separator)

    -- Calculate space used by left/right components
    local left_width = 0
    local right_width = 0
    for _, comp in ipairs(state.left) do
      if type(comp) == "string" then
        left_width = left_width + util.strdisplaywidth(comp)
      elseif type(comp) == "table" and comp.render_left then
        -- Estimate width for arrows
        left_width = left_width + 3
      end
    end
    for _, comp in ipairs(state.right) do
      if type(comp) == "string" then
        right_width = right_width + util.strdisplaywidth(comp)
      elseif type(comp) == "table" and comp.render_right then
        right_width = right_width + 3
      end
    end

    local avail_width = editor_width - left_width - right_width

    -- Compute page
    local page_start, page_end =
      make_page(ctx.selected, total, candidates, avail_width, sep_width, state.page)
    state.page = { page_start, page_end }

    if page_start == -1 then
      self:hide()
      return
    end

    -- Get query for highlighting
    local query = ""
    if result.data then
      query = result.data.arg or result.data.input or ""
    end

    -- Build the line as chunks
    local chunks = {}
    local comp_ctx = {
      selected = ctx.selected,
      total = total,
      page_start = page_start,
      page_end = page_end,
    }

    -- Left components
    for _, comp in ipairs(state.left) do
      if type(comp) == "string" then
        table.insert(chunks, { comp, state.highlights.default })
      elseif type(comp) == "table" and comp.render_left then
        local parts = comp:render_left(comp_ctx)
        if parts then
          for _, p in ipairs(parts) do
            table.insert(chunks, p)
          end
        end
      elseif type(comp) == "table" and comp.render then
        comp_ctx.side = "left"
        local parts = comp:render(comp_ctx)
        if parts then
          for _, p in ipairs(parts) do
            table.insert(chunks, p)
          end
        end
      end
    end

    -- Candidates
    for i = page_start, page_end do
      if i > page_start then
        table.insert(chunks, { state.separator, state.highlights.default })
      end

      local candidate = candidates[i + 1]
      local is_selected = (i == ctx.selected)
      local base_hl = is_selected and state.highlights.selected or state.highlights.default
      local accent_hl = is_selected and state.highlights.selected_accent or state.highlights.accent

      -- Get highlight spans
      local spans = {}
      if state.highlighter and query ~= "" then
        spans = state.highlighter.highlight(query, candidate) or {}
      end

      if #spans > 0 then
        -- Convert spans to chunks
        local cand_chunks = hl_mod.spans_to_chunks(candidate, spans, base_hl)
        -- Override accent highlights
        for _, cc in ipairs(cand_chunks) do
          if cc[2] ~= base_hl then
            cc[2] = accent_hl
          end
          table.insert(chunks, cc)
        end
      else
        table.insert(chunks, { candidate, base_hl })
      end
    end

    -- Right components
    for _, comp in ipairs(state.right) do
      if type(comp) == "string" then
        table.insert(chunks, { comp, state.highlights.default })
      elseif type(comp) == "table" and comp.render_right then
        local parts = comp:render_right(comp_ctx)
        if parts then
          for _, p in ipairs(parts) do
            table.insert(chunks, p)
          end
        end
      elseif type(comp) == "table" and comp.render then
        comp_ctx.side = "right"
        local parts = comp:render(comp_ctx)
        if parts then
          for _, p in ipairs(parts) do
            table.insert(chunks, p)
          end
        end
      end
    end

    -- Pad to fill width
    local total_width = 0
    for _, chunk in ipairs(chunks) do
      total_width = total_width + util.strdisplaywidth(chunk[1])
    end
    if total_width < editor_width then
      table.insert(
        chunks,
        { string.rep(" ", editor_width - total_width), state.highlights.default }
      )
    end

    -- Build single line from chunks
    local line = ""
    for _, chunk in ipairs(chunks) do
      line = line .. chunk[1]
    end

    -- Set buffer
    vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, { line })
    vim.api.nvim_buf_clear_namespace(state.buf, state.ns_id, 0, -1)

    -- Apply highlights from chunks
    local col = 0
    for _, chunk in ipairs(chunks) do
      local len = #chunk[1]
      if chunk[2] and chunk[2] ~= "" then
        vim.api.nvim_buf_set_extmark(state.buf, state.ns_id, 0, col, {
          end_col = col + len,
          hl_group = chunk[2],
          priority = 1000,
        })
      end
      col = col + len
    end

    -- Position: single line above cmdline
    local row = vim.o.lines - 2
    local win_config = {
      relative = "editor",
      row = row,
      col = 0,
      width = editor_width,
      height = 1,
      style = "minimal",
      border = "none",
      zindex = state.zindex,
      focusable = false,
      noautocmd = true,
    }

    renderer_util.open_or_update_win(state, win_config)
  end

  --- Hide the wildmenu
  function renderer:hide()
    renderer_util.hide_win(state)
  end

  return renderer
end

return M
