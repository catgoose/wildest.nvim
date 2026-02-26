---@mod wildest.renderer.components.scrollbar Scrollbar Thumb Component
---@brief [[
---Scrollbar thumb component.
---@brief ]]

local M = {}

--- Create a scrollbar component for the popupmenu
---@param opts? table { thumb?: string, bar?: string, hl?: string, thumb_hl?: string }
---@return table component
function M.new(opts)
  opts = opts or {}
  local thumb_char = opts.thumb or "█"
  local bar_char = opts.bar or " "
  local bar_hl = opts.hl or "PmenuSbar"
  local thumb_hl = opts.thumb_hl or "PmenuThumb"

  local component = {}

  function component:render(ctx)
    local total = ctx.total or 0
    local page_start = ctx.page_start or 0
    local page_end = ctx.page_end or 0
    local index = ctx.index or 0

    if total <= 0 then
      return { { bar_char, bar_hl } }
    end

    local page_size = page_end - page_start + 1
    if page_size >= total then
      return { { bar_char, bar_hl } }
    end

    -- Calculate thumb position for this line
    local thumb_size = math.max(1, math.floor(page_size * page_size / total + 0.5))
    local thumb_start = math.floor(page_start * page_size / total + 0.5)
    local thumb_end = thumb_start + thumb_size - 1

    local line_in_page = index - page_start
    if line_in_page >= thumb_start and line_in_page <= thumb_end then
      return { { thumb_char, thumb_hl } }
    else
      return { { bar_char, bar_hl } }
    end
  end

  return component
end

return M
