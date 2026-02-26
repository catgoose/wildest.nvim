---@mod wildest.renderer Renderer Utilities
---@brief [[
---Shared renderer infrastructure for wildest.nvim.
---Provides line rendering, pagination, floating window management,
---highlight application, and component composition used by all renderer types.
---@brief ]]

---@class wildest.Renderer
---@field render fun(self: wildest.Renderer, ctx: table, result: wildest.PipelineResult)
---@field hide fun(self: wildest.Renderer)

---@class wildest.Component
---@field render fun(self: wildest.Component, ctx: table): table[]|nil

---@class wildest.Theme
---@field apply fun(self: wildest.Theme)
---@field renderer fun(self: wildest.Theme, opts?: table): wildest.Renderer

---@class wildest.ThemeDef
---@field highlights? table<string, table> Highlight group definitions
---@field border? string|table Border style
---@field renderer? string Renderer type name
---@field renderer_opts? table Renderer options

---@class wildest.ResultOpts
---@field highlighter? wildest.Highlighter
---@field output? fun(data: table, candidate: any): string

local hl_mod = require("wildest.highlight")
local log = require("wildest.log")
local util = require("wildest.util")

local M = {}

--- Parse a dimension value: integer, percentage string, or 'auto'
---@param value any
---@param total integer
---@return integer
function M.parse_dimension(value, total)
  if type(value) == "number" then
    return value
  end
  if type(value) == "string" then
    local pct = value:match("^(%d+)%%$")
    if pct then
      return math.floor(tonumber(pct) / 100 * total)
    end
  end
  return total
end

--- Parse margin: number, percentage string, or 'auto'
---@param margin any
---@param total integer
---@param content_size integer
---@return integer
function M.parse_margin(margin, total, content_size)
  if margin == "auto" then
    return math.floor((total - content_size) / 2)
  end
  if type(margin) == "number" then
    return margin
  end
  if type(margin) == "string" then
    local pct = margin:match("^(%d+)%%$")
    if pct then
      return math.floor(tonumber(pct) / 100 * total)
    end
  end
  return 0
end

local cache_mod = require("wildest.cache")

--- Create the common state table shared by all popupmenu-style renderers
---@param opts table renderer options
---@param defaults? table override default values (e.g. { max_height = "75%", max_width = "75%", min_width = 30 })
---@return table state
function M.create_base_state(opts, defaults)
  defaults = defaults or {}
  return {
    highlights = {
      default = opts.hl or "Pmenu",
      selected = opts.selected_hl or "PmenuSel",
      error = opts.error_hl or "ErrorMsg",
      accent = nil,
      selected_accent = nil,
    },
    max_height = opts.max_height or defaults.max_height or 16,
    min_height = opts.min_height or defaults.min_height or 0,
    max_width = opts.max_width or defaults.max_width,
    min_width = opts.min_width or defaults.min_width or 16,
    pumblend = opts.pumblend,
    left = opts.left or { " " },
    right = opts.right or { " " },
    highlighter = opts.highlighter,
    reverse = opts.reverse or false,
    ellipsis = opts.ellipsis or "...",
    zindex = opts.zindex or 250,
    fixed_height = opts.fixed_height ~= false,

    buf = -1,
    win = -1,
    ns_id = -1,
    page = { -1, -1 },
    run_id = -1,
    draw_cache = cache_mod.dict_cache(),
    highlight_cache = cache_mod.dict_cache(),
  }
end

--- Create accent + selected-accent highlight groups on a state table
---@param state table renderer state (mutated: sets highlights.accent, highlights.selected_accent)
function M.create_accent_highlights(state)
  state.highlights.accent =
    hl_mod.hl_with_attr("WildestAccent", state.highlights.default, "underline", "bold")
  state.highlights.selected_accent =
    hl_mod.hl_with_attr("WildestSelectedAccent", state.highlights.selected, "underline", "bold")
end

---Truncate a string to fit within max_width, preserving highlight spans.
---@param text string
---@param spans table[]|nil
---@param max_width integer
---@param ellipsis? string
---@return string truncated_text, table[] adjusted_spans
function M.truncate_with_spans(text, spans, max_width, ellipsis)
  ellipsis = ellipsis or "..."
  local width = util.strdisplaywidth(text)

  if width <= max_width then
    return text, spans or {}
  end

  local ellipsis_width = util.strdisplaywidth(ellipsis)
  local target = max_width - ellipsis_width
  if target <= 0 then
    return ellipsis:sub(1, max_width), {}
  end

  -- Truncate text
  local result = ""
  local cur_width = 0
  local byte_pos = 0

  for p, code in utf8.codes(text) do
    local c = utf8.char(code)
    local cw = util.strdisplaywidth(c)
    if cur_width + cw > target then
      break
    end
    result = result .. c
    cur_width = cur_width + cw
    byte_pos = p + #c - 1
  end

  -- Adjust spans to fit truncated text
  local adjusted = {}
  if spans then
    for _, span in ipairs(spans) do
      local s_start = span[1]
      local s_len = span[2]
      local s_hl = span[3]
      local s_end = s_start + s_len

      if s_start < byte_pos then
        local new_end = math.min(s_end, byte_pos)
        table.insert(adjusted, { s_start, new_end - s_start, s_hl })
      end
    end
  end

  return result .. ellipsis, adjusted
end

--- Render a line with left/right components
--- Returns the full line text and all highlight spans
---@param candidate string
---@param left_parts table[] array of {text, hl_group}
---@param right_parts table[] array of {text, hl_group}
---@param candidate_spans table[]|nil highlight spans for the candidate
---@param max_width integer
---@param default_hl string
---@return string line, table[] spans
function M.render_line(candidate, left_parts, right_parts, candidate_spans, max_width, default_hl)
  -- Calculate widths
  local left_width = 0
  local left_text = ""
  for _, part in ipairs(left_parts) do
    left_width = left_width + util.strdisplaywidth(part[1])
    left_text = left_text .. part[1]
  end

  local right_width = 0
  local right_text = ""
  for _, part in ipairs(right_parts) do
    right_width = right_width + util.strdisplaywidth(part[1])
    right_text = right_text .. part[1]
  end

  -- Available width for the candidate
  local avail = max_width - left_width - right_width
  if avail < 1 then
    avail = 1
  end

  -- Truncate candidate if needed
  local display_candidate, adj_spans = M.truncate_with_spans(candidate, candidate_spans, avail)

  -- Pad candidate to fill available space
  local cand_width = util.strdisplaywidth(display_candidate)
  local padding = ""
  if cand_width < avail then
    padding = string.rep(" ", avail - cand_width)
  end

  -- Build the full line
  local line = left_text .. display_candidate .. padding .. right_text

  -- Build spans for the full line
  local all_spans = {}
  local offset = 0

  -- Left component spans
  for _, part in ipairs(left_parts) do
    local len = #part[1]
    if part[2] and part[2] ~= default_hl then
      table.insert(all_spans, { offset, len, part[2] })
    end
    offset = offset + len
  end

  -- Candidate spans (shifted by left width)
  local cand_offset = #left_text
  if adj_spans then
    for _, span in ipairs(adj_spans) do
      table.insert(all_spans, { span[1] + cand_offset, span[2], span[3] })
    end
  end

  -- Right component spans
  offset = #left_text + #display_candidate + #padding
  for _, part in ipairs(right_parts) do
    local len = #part[1]
    if part[2] and part[2] ~= default_hl then
      table.insert(all_spans, { offset, len, part[2] })
    end
    offset = offset + len
  end

  return line, all_spans
end

-- Shared renderer infrastructure
-- These functions are used by popupmenu, popupmenu_border, and popupmenu_palette

--- Compute visible page range
---@param selected integer (-1 = no selection)
---@param total integer
---@param max_height integer
---@param current_page table {start, finish}
---@return integer start, integer finish (0-indexed, inclusive)
function M.make_page(selected, total, max_height, current_page)
  if total == 0 then
    return -1, -1
  end
  local page_size = math.min(total, max_height)
  if selected == -1 then
    return 0, page_size - 1
  end

  local start = current_page[1]
  local finish = current_page[2]

  if start == -1 or finish == -1 then
    start = math.max(0, selected - math.floor(page_size / 2))
    finish = start + page_size - 1
    if finish >= total then
      finish = total - 1
      start = math.max(0, finish - page_size + 1)
    end
    return start, finish
  end

  if selected >= start and selected <= finish then
    return start, finish
  end
  if selected > finish then
    finish = selected
    start = finish - page_size + 1
    return math.max(0, start), finish
  end
  start = selected
  finish = start + page_size - 1
  return start, math.min(total - 1, finish)
end

--- Default position: above the cmdline, left-aligned, full width
---@return integer row, integer col, integer width
function M.default_position()
  local height = vim.o.lines
  local width = vim.o.columns
  return height - 2, 0, width
end

--- Ensure a scratch buffer and namespace exist
---@param state table renderer state (mutated: sets .buf and .ns_id)
---@param ns_name string namespace name
function M.ensure_buf(state, ns_name)
  local created = false
  if not vim.api.nvim_buf_is_valid(state.buf) then
    state.buf = vim.api.nvim_create_buf(false, true)
    vim.bo[state.buf].bufhidden = "hide"
    vim.bo[state.buf].buftype = "nofile"
    created = true
  end
  if state.ns_id == -1 then
    state.ns_id = vim.api.nvim_create_namespace(ns_name)
  end
  log.log("renderer", "ensure_buf", { created = created, buf = state.buf })
end

--- Render left/right components for a candidate line
---@param state table renderer state
---@param ctx table render context
---@param result table pipeline result
---@param index integer 0-indexed candidate index
---@param is_selected boolean
---@return table[] left_parts, table[] right_parts
function M.render_components(state, ctx, result, index, is_selected)
  local left_parts = {}
  local right_parts = {}
  local hl = is_selected and state.highlights.selected or state.highlights.default

  local comp_ctx = {
    selected = ctx.selected,
    index = index,
    total = #result.value,
    page_start = state.page[1],
    page_end = state.page[2],
    is_selected = is_selected,
    result = result,
    default_hl = state.highlights.default,
    selected_hl = state.highlights.selected,
  }

  for _, comp in ipairs(state.left) do
    if type(comp) == "string" then
      table.insert(left_parts, { comp, hl })
    elseif type(comp) == "table" and comp.render then
      local parts = comp:render(comp_ctx)
      if parts then
        for _, p in ipairs(parts) do
          if not p[2] or p[2] == "" then
            p[2] = hl
          end
          table.insert(left_parts, p)
        end
      end
    end
  end

  for _, comp in ipairs(state.right) do
    if type(comp) == "string" then
      table.insert(right_parts, { comp, hl })
    elseif type(comp) == "table" and comp.render then
      local parts = comp:render(comp_ctx)
      if parts then
        for _, p in ipairs(parts) do
          if not p[2] or p[2] == "" then
            p[2] = hl
          end
          table.insert(right_parts, p)
        end
      end
    end
  end

  return left_parts, right_parts
end

--- Apply line highlights (base hl + accent spans) to buffer
---@param buf integer buffer handle
---@param ns_id integer namespace id
---@param lines string[] line texts
---@param line_highlights table[] per-line {spans, base_hl}
function M.apply_line_highlights(buf, ns_id, lines, line_highlights)
  vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
  for line_idx, hl_info in ipairs(line_highlights) do
    local l = line_idx - 1
    vim.api.nvim_buf_set_extmark(buf, ns_id, l, 0, {
      end_col = #lines[line_idx],
      hl_group = hl_info.base_hl,
      hl_eol = true,
      priority = 100,
    })
    hl_mod.apply_spans(buf, ns_id, l, hl_info.spans)
  end
end

--- Open or update a floating window
---@param state table renderer state (mutated: sets .win)
---@param win_config table nvim_open_win config
function M.open_or_update_win(state, win_config)
  if vim.api.nvim_win_is_valid(state.win) then
    log.log(
      "renderer",
      "update_win",
      { win = state.win, width = win_config.width, height = win_config.height }
    )
    vim.api.nvim_win_set_config(state.win, win_config)
    vim.api.nvim_win_set_buf(state.win, state.buf)
  else
    log.log("renderer", "open_win", {
      width = win_config.width,
      height = win_config.height,
      row = win_config.row,
      col = win_config.col,
    })
    state.win = vim.api.nvim_open_win(state.buf, false, win_config)
    log.log("renderer", "open_win_done", { win = state.win })
    if state.pumblend and state.pumblend >= 0 then
      vim.wo[state.win].winblend = state.pumblend
    end
    local default_hl = state.highlights.default or "Pmenu"
    vim.wo[state.win].winhighlight = "Normal:" .. default_hl .. ",NormalFloat:" .. default_hl
    vim.wo[state.win].foldenable = false
    vim.wo[state.win].wrap = false
    vim.wo[state.win].cursorline = false
  end
end

--- Hide a floating window
---@param state table renderer state (mutated: sets .win, .page)
function M.hide_win(state)
  log.log("renderer", "hide_win", { valid = vim.api.nvim_win_is_valid(state.win), win = state.win })
  if vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
    state.win = -1
  end
  state.page = { -1, -1 }
end

--- Get highlight spans for a candidate
---@param highlighter table|nil
---@param query string
---@param candidate string
---@param accent_hl string
---@return table[]
function M.get_candidate_spans(highlighter, query, candidate, accent_hl)
  local spans = {}
  if highlighter and query ~= "" then
    local raw = highlighter.highlight(query, candidate)
    if raw then
      for _, span in ipairs(raw) do
        table.insert(spans, { span[1], span[2], accent_hl })
      end
    end
  end
  return spans
end

--- Extract query string from result data
---@param result table
---@return string
function M.get_query(result)
  if result.data then
    return result.data.arg or result.data.input or ""
  end
  return ""
end

--- Check if run_id changed and reset caches
---@param state table renderer state
---@param ctx table render context
function M.check_run_id(state, ctx)
  if ctx.run_id ~= state.run_id then
    state.run_id = ctx.run_id
    if state.draw_cache then
      state.draw_cache.clear()
    end
    if state.highlight_cache then
      state.highlight_cache.clear()
    end
    state.page = { -1, -1 }
  end
end

return M
