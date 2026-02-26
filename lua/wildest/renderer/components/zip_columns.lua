---@mod wildest.renderer.components.zip_columns Merge Two Column Components
---@brief [[
---Merge two column components.
---@brief ]]

local M = {}

--- Create a zip columns component that merges two column components
--- Each column renders independently, then a merger function combines them.
---
--- Example:
---   w.popupmenu_zip_columns(
---     function(ctx, result, left_chunks, right_chunks)
---       -- Combine chunks side by side
---       local merged = {}
---       for _, c in ipairs(left_chunks) do table.insert(merged, c) end
---       table.insert(merged, { '  ', 'Pmenu' })
---       for _, c in ipairs(right_chunks) do table.insert(merged, c) end
---       return merged
---     end,
---     w.popupmenu_devicons(),
---     w.popupmenu_buffer_flags()
---   )
---
---@param merger function(ctx, result, chunks1, chunks2): table
---@param col1 table component
---@param col2 table component
---@return table component
function M.new(merger, col1, col2)
  local component = {}

  function component:render(ctx)
    local parts1 = {}
    local parts2 = {}

    if col1 and col1.render then
      parts1 = col1:render(ctx) or {}
    end

    if col2 and col2.render then
      parts2 = col2:render(ctx) or {}
    end

    if merger then
      local result = ctx.result
      return merger(ctx, result, parts1, parts2)
    end

    -- Default: concatenate
    local merged = {}
    for _, p in ipairs(parts1) do
      table.insert(merged, p)
    end
    for _, p in ipairs(parts2) do
      table.insert(merged, p)
    end
    return merged
  end

  return component
end

return M
