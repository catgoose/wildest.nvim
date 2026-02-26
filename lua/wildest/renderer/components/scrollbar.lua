---@mod wildest.renderer.components.scrollbar Scrollbar Thumb Component
---@brief [[
---Scrollbar thumb component.
---@brief ]]

local M = {}

--- Create a scrollbar component for the popupmenu
---@param opts? table { thumb?: string, bar?: string, hl?: string, thumb_hl?: string }
---@return table component
--- Resolve scrollbar highlight: prefer theme group if it exists, then user opt, then fallback
---@param group string theme highlight group name
---@param fallback string default highlight group
---@return string
local function resolve_hl(group, fallback)
  local existing = vim.api.nvim_get_hl(0, { name = group, link = false })
  if not vim.tbl_isempty(existing) then
    return group
  end
  return fallback
end

function M.new(opts)
  opts = opts or {}
  local thumb_char = opts.thumb or "█"
  local bar_char = opts.bar or " "
  local bar_hl = opts.hl or resolve_hl("WildestScrollbar", "PmenuSbar")
  local thumb_hl = opts.thumb_hl or resolve_hl("WildestScrollbarThumb", "PmenuThumb")

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
