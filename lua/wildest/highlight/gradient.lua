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
      local len = span[2] -- byte length
      local substr = candidate:sub(start + 1, start + len)

      -- Split span into individual characters
      local byte_offset = 0
      for pos, code in utf8.codes(substr) do
        local char = utf8.char(code)
        local char_byte_len = #char

        -- Pick gradient color by character position in match
        local grad_idx = math.min(char_index + 1, #gradient)
        local grad_hl = gradient[grad_idx]

        -- Also compute selected gradient if available
        local sel_grad_hl = nil
        if selected_gradient and #selected_gradient > 0 then
          local sel_idx = math.min(char_index + 1, #selected_gradient)
          sel_grad_hl = selected_gradient[sel_idx]
        end

        table.insert(gradient_spans, {
          start + pos - 1, -- 0-indexed byte position in full candidate
          char_byte_len,
          grad_hl,
          sel_grad_hl, -- optional 4th element for selected state
        })

        char_index = char_index + 1
      end
    end

    return gradient_spans
  end

  return highlighter
end

return M
