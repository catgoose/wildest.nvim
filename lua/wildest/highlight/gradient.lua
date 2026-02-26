---@mod wildest.highlight.gradient Gradient per-character color highlighter
---@brief [[
---Gradient per-character color highlighter.
---@brief ]]

local M = {}

--- Create a gradient highlighter that applies per-character color gradients
--- Wraps an existing highlighter, splitting its spans into individual characters
--- each with a gradient color from the provided array.
---
--- Example:
---   local gradient_colors = {}
---   for i = 0, 15 do
---     local hex = string.format('#%02x%02x%02x', 255 - i * 16, i * 8, i * 16)
---     local name = 'WildestGradient' .. i
---     vim.api.nvim_set_hl(0, name, { fg = hex })
---     table.insert(gradient_colors, name)
---   end
---   w.gradient_highlighter(w.basic_highlighter(), gradient_colors)
---
---@param base_highlighter table highlighter with .highlight(query, candidate) method
---@param gradient table array of highlight group names
---@param opts? table { selected_gradient?: table }
---@return table highlighter
function M.new(base_highlighter, gradient, opts)
  opts = opts or {}
  local selected_gradient = opts.selected_gradient

  if not gradient or #gradient == 0 then
    return base_highlighter
  end

  local highlighter = {}

  --- Get highlight spans with gradient colors applied per character
  ---@param query string
  ---@param candidate string
  ---@return table[] spans
  function highlighter.highlight(query, candidate)
    -- Get base spans
    local base_spans = base_highlighter.highlight(query, candidate)
    if not base_spans or #base_spans == 0 then
      return {}
    end

    local gradient_spans = {}
    local char_index = 0

    for _, span in ipairs(base_spans) do
      local start = span[1] -- 0-indexed byte position
      local len = span[2]   -- byte length

      -- Split multi-byte spans into per-character spans so each
      -- matched character gets its own gradient color.
      for offset = 0, len - 1 do
        char_index = char_index + 1
        local grad_idx = math.min(char_index, #gradient)
        local grad_hl = gradient[grad_idx]

        local sel_grad_hl = nil
        if selected_gradient and #selected_gradient > 0 then
          local sel_idx = math.min(char_index, #selected_gradient)
          sel_grad_hl = selected_gradient[sel_idx]
        end

        table.insert(gradient_spans, {
          start + offset, -- 0-indexed byte position
          1,              -- single byte
          grad_hl,
          sel_grad_hl,
        })
      end
    end

    return gradient_spans
  end

  return highlighter
end

return M
