---@mod wildest.highlight.basic Basic subsequence highlighter
---@brief [[
---Basic subsequence highlighter.
---@brief ]]

local M = {}

--- Create a basic subsequence highlighter
--- Highlights each character of the query that matches in the candidate
---@param opts? table { hl?: string }
---@return table highlighter with :highlight(query, candidate) method
function M.new(opts)
  opts = opts or {}
  local hl_group = opts.hl or "WildestAccent"

  local highlighter = {}

  --- Get highlight spans for a candidate
  ---@param query string the search query
  ---@param candidate string the candidate text
  ---@return table[] spans array of {start_col, length, hl_group}
  function highlighter.highlight(query, candidate)
    if not query or query == "" then
      return {}
    end

    local spans = {}
    local qi = 1
    local ci = 1
    local q_lower = query:lower()
    local c_lower = candidate:lower()

    -- Track consecutive matches to merge spans
    local span_start = nil
    local span_len = 0

    while qi <= #q_lower and ci <= #c_lower do
      if q_lower:sub(qi, qi) == c_lower:sub(ci, ci) then
        if span_start == nil then
          span_start = ci - 1 -- 0-indexed
          span_len = 1
        else
          span_len = span_len + 1
        end
        qi = qi + 1
      else
        if span_start ~= nil then
          table.insert(spans, { span_start, span_len, hl_group })
          span_start = nil
          span_len = 0
        end
      end
      ci = ci + 1
    end

    -- Flush last span
    if span_start ~= nil then
      table.insert(spans, { span_start, span_len, hl_group })
    end

    return spans
  end

  return highlighter
end

return M
