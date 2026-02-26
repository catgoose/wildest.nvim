---@mod wildest.highlight.prefix Prefix highlighter
---@brief [[
---Prefix highlighter — highlights the leading substring that matches the query.
---@brief ]]

local M = {}

--- Create a prefix highlighter
--- Highlights the longest leading prefix of the candidate that matches the query.
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

    local q_lower = query:lower()
    local c_lower = candidate:lower()
    local len = math.min(#q_lower, #c_lower)
    local match_len = 0

    for i = 1, len do
      if q_lower:sub(i, i) == c_lower:sub(i, i) then
        match_len = i
      else
        break
      end
    end

    if match_len == 0 then
      return {}
    end

    return { { 0, match_len, hl_group } }
  end

  return highlighter
end

return M
