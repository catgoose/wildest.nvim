---@mod wildest.highlight Highlight Utilities
---@brief [[
---Highlight group creation, span conversion, and extmark application utilities.
---Used by renderers and highlighters to apply fuzzy match highlighting.
---@brief ]]

---@class wildest.Highlighter
---@field highlight fun(query: string, candidate: string): table[]|nil

local M = {}

---Create or update a highlight group by extending a base group.
---@param name string the new highlight group name
---@param base string the base highlight group to extend
---@param overrides table highlight attributes to override
---@return string the highlight group name
function M.make_hl(name, base, overrides)
  local hl = vim.api.nvim_get_hl(0, { name = base, link = false })
  vim.api.nvim_set_hl(0, name, vim.tbl_extend("force", hl, overrides))
  return name
end

--- Create a highlight group with additional attributes
---@param name string
---@param base string
---@param ... string attribute names (e.g., 'bold', 'underline', 'italic')
---@return string
function M.hl_with_attr(name, base, ...)
  local attrs = {}
  for _, attr in ipairs({ ... }) do
    attrs[attr] = true
  end
  return M.make_hl(name, base, attrs)
end

--- Convert spans to extmark-compatible chunks
--- Spans: { {start_col, length, hl_group}, ... }
--- Returns chunks suitable for nvim_buf_set_extmark virt_text
---@param text string the full text
---@param spans table[] array of {start, length, hl_group}
---@param default_hl string default highlight group
---@return table[] chunks array of {text, hl_group}
function M.spans_to_chunks(text, spans, default_hl)
  if not spans or #spans == 0 then
    return { { text, default_hl } }
  end

  -- Sort spans by start position
  table.sort(spans, function(a, b)
    return a[1] < b[1]
  end)

  local chunks = {}
  local pos = 1

  for _, span in ipairs(spans) do
    local start = span[1] + 1 -- Convert 0-indexed to 1-indexed
    local len = span[2]
    local hl = span[3]

    -- Add text before this span with default highlight
    if start > pos then
      table.insert(chunks, { text:sub(pos, start - 1), default_hl })
    end

    -- Add the highlighted span
    local span_end = start + len - 1
    if span_end > #text then
      span_end = #text
    end
    if start <= #text then
      table.insert(chunks, { text:sub(start, span_end), hl })
    end

    pos = span_end + 1
  end

  -- Add remaining text
  if pos <= #text then
    table.insert(chunks, { text:sub(pos), default_hl })
  end

  return chunks
end

--- Apply highlight spans to a buffer line using extmarks
---@param bufnr integer
---@param ns_id integer
---@param line integer 0-indexed line number
---@param spans table[] array of {start_col, length, hl_group}
function M.apply_spans(bufnr, ns_id, line, spans)
  if not spans then
    return
  end
  for _, span in ipairs(spans) do
    local start_col = span[1]
    local end_col = start_col + span[2]
    local hl = span[3]
    pcall(vim.api.nvim_buf_set_extmark, bufnr, ns_id, line, start_col, {
      end_col = end_col,
      hl_group = hl,
      priority = 1000,
    })
  end
end

return M
