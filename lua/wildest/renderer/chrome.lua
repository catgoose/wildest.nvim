--- Chrome line resolution for top/bottom popupmenu components.
--- Each component can be a string, a function, or a table with value/hooks.

local M = {}

--- Resolve a single chrome component to text and highlight spans.
---@param comp string|function|table
---@param ctx table chrome context
---@return string|nil text, table[]|nil spans
local function resolve_one(comp, ctx)
  local value, pre_hook, post_hook

  if type(comp) == "table" then
    value = comp.value
    pre_hook = comp.pre_hook
    post_hook = comp.post_hook
  else
    value = comp
  end

  if pre_hook then
    pre_hook(ctx)
  end

  local text, spans
  if type(value) == "function" then
    local result = value(ctx)
    if result == nil or result == "" then
      if post_hook then
        post_hook(ctx)
      end
      return nil, nil
    end
    if type(result) == "table" then
      -- Chunk array: { {text, hl}, ... }
      local parts = {}
      spans = {}
      local offset = 0
      for _, chunk in ipairs(result) do
        local chunk_text = chunk[1] or ""
        local chunk_hl = chunk[2]
        parts[#parts + 1] = chunk_text
        if chunk_hl and chunk_hl ~= "" then
          spans[#spans + 1] = { offset, #chunk_text, chunk_hl }
        end
        offset = offset + #chunk_text
      end
      text = table.concat(parts)
    else
      text = tostring(result)
    end
  elseif type(value) == "string" then
    if value == "" then
      if post_hook then
        post_hook(ctx)
      end
      return nil, nil
    end
    text = value
  else
    if post_hook then
      post_hook(ctx)
    end
    return nil, nil
  end

  if post_hook then
    post_hook(ctx)
  end

  return text, spans
end

--- Resolve an array of chrome components into lines and highlights.
---@param components (string|function|table)[]
---@param ctx table chrome context
---@param width integer target line width
---@param base_hl string default highlight group
---@return string[] lines, table[] line_highlights, integer count
function M.resolve_chrome_lines(components, ctx, width, base_hl)
  if not components or #components == 0 then
    return {}, {}, 0
  end

  local lines = {}
  local line_highlights = {}

  for _, comp in ipairs(components) do
    local text, spans = resolve_one(comp, ctx)
    if text then
      -- Pad to width
      local text_width = vim.api.nvim_strwidth(text)
      if text_width < width then
        text = text .. string.rep(" ", width - text_width)
      end
      lines[#lines + 1] = text
      line_highlights[#line_highlights + 1] = { spans = spans or {}, base_hl = base_hl }
    end
  end

  return lines, line_highlights, #lines
end

return M
