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
      -- Check if this is a multi-line result (text contains newlines)
      if text:find("\n") then
        local line_texts = vim.split(text, "\n", { plain = true })
        -- Distribute spans across lines by byte offset
        local byte_offset = 0
        for li, lt in ipairs(line_texts) do
          local line_spans = {}
          if spans then
            local line_start = byte_offset
            local line_end = byte_offset + #lt
            for _, s in ipairs(spans) do
              local s_start, s_len, s_hl = s[1], s[2], s[3]
              local s_end = s_start + s_len
              if s_start < line_end and s_end > line_start then
                local adj_start = math.max(0, s_start - line_start)
                local adj_end = math.min(#lt, s_end - line_start)
                if adj_end > adj_start then
                  line_spans[#line_spans + 1] = { adj_start, adj_end - adj_start, s_hl }
                end
              end
            end
          end
          -- Pad to width
          local text_width = vim.api.nvim_strwidth(lt)
          if text_width < width then
            lt = lt .. string.rep(" ", width - text_width)
          end
          lines[#lines + 1] = lt
          line_highlights[#line_highlights + 1] = { spans = line_spans, base_hl = base_hl }
          byte_offset = byte_offset + #line_texts[li] + 1 -- +1 for the \n
        end
      else
        -- Pad to width
        local text_width = vim.api.nvim_strwidth(text)
        if text_width < width then
          text = text .. string.rep(" ", width - text_width)
        end
        lines[#lines + 1] = text
        line_highlights[#line_highlights + 1] = { spans = spans or {}, base_hl = base_hl }
      end
    end
  end

  return lines, line_highlights, #lines
end

return M
