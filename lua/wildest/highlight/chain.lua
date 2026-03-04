---@mod wildest.highlight.chain Chain highlighter (fallback list)
---@brief [[
---Chain highlighter that tries multiple highlighters in order.
---The first to return non-empty spans wins.
---@brief ]]

local M = {}

--- Create a chain highlighter that tries each highlighter in order
--- Returns spans from the first highlighter that produces a non-empty result.
---
--- Example:
---   w.chain_highlighter({
---     w.fzy_highlighter(),
---     w.basic_highlighter(),
---   })
---
---@param highlighters table[] array of highlighter instances with .highlight(query, candidate)
---@return table highlighter
function M.new(highlighters)
  local hl = {}

  --- Get highlight spans by trying each highlighter in order
  ---@param query string
  ---@param candidate string
  ---@return table[] spans
  function hl.highlight(query, candidate)
    for _, h in ipairs(highlighters) do
      local spans = h.highlight(query, candidate)
      if spans and #spans > 0 then
        return spans
      end
    end
    return {}
  end

  return hl
end

return M
