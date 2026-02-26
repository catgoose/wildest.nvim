---@mod wildest.highlight.fzy FFI-based fzy highlighter
---@brief [[
---FFI-based fzy highlighter.
---@brief ]]

local filter = require("wildest.filter")

local M = {}

--- Create a fzy C FFI highlighter
--- Uses C FFI position extraction for optimal highlight positions
---@param opts? table { hl?: string }
---@return table highlighter with :highlight(query, candidate) method
function M.new(opts)
  opts = opts or {}
  local hl_group = opts.hl or "WildestAccent"

  local highlighter = {}

  --- Get highlight spans for a candidate using fzy positions
  ---@param query string
  ---@param candidate string
  ---@return table[] spans array of {start_col, length, hl_group}
  function highlighter.highlight(query, candidate)
    if not query or query == "" then
      return {}
    end

    if not filter.has_match(query, candidate) then
      return {}
    end

    local positions = filter.positions(query, candidate)
    if not positions or #positions == 0 then
      return {}
    end

    -- Merge consecutive positions into spans
    local spans = {}
    local start = positions[1]
    local finish = positions[1]

    for i = 2, #positions do
      local current = positions[i]
      if current == finish + 1 then
        finish = current
      else
        table.insert(spans, { start, finish - start + 1, hl_group })
        start = current
        finish = current
      end
    end

    table.insert(spans, { start, finish - start + 1, hl_group })

    return spans
  end

  return highlighter
end

return M
