---@mod wildest.renderer.components.scrollbar Scrollbar Thumb Component
---@brief [[
---Scrollbar thumb component.
---@brief ]]

local BaseComponent = require("wildest.renderer.components.base")
local M = {}

--- Resolve a highlight group's bg color (follows links).
---@param name string
---@return integer|nil
local function resolve_bg(name)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
  return ok and hl and hl.bg or nil
end

--- Create a scrollbar component for the popupmenu
---@param opts? table { thumb?: string, bar?: string, hl?: string, thumb_hl?: string, collapse?: boolean }
---@return table component
function M.new(opts)
  opts = opts or {}
  local thumb_char = opts.thumb or "█"
  local bar_char = opts.bar or " "
  local bar_hl = opts.hl or "WildestScrollbar"
  local thumb_hl = opts.thumb_hl or "WildestScrollbarThumb"
  local collapse = opts.collapse or false

  -- Hl group for bar on selected line: block char with cursorline bg as fg
  local bar_sel_hl = bar_hl .. "Sel"
  local bar_sel_set = false

  local component = setmetatable({}, { __index = BaseComponent })

  function component:render(ctx)
    local total = ctx.total or 0
    local page_start = ctx.page_start or 0
    local page_end = ctx.page_end or 0
    local index = ctx.index or 0
    local is_selected = ctx.is_selected

    if total <= 0 then
      if collapse then
        return {}
      end
      if is_selected then
        return self:_sel_bar(ctx)
      end
      return { { bar_char, bar_hl } }
    end

    local page_size = page_end - page_start + 1
    if page_size >= total then
      if collapse then
        return {}
      end
      if is_selected then
        return self:_sel_bar(ctx)
      end
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
      if is_selected then
        return self:_sel_bar(ctx)
      end
      return { { bar_char, bar_hl } }
    end
  end

  --- Render bar on selected line: block char with cursorline bg as fg
  function component:_sel_bar(ctx)
    if not bar_sel_set then
      local sel_bg = resolve_bg(ctx.selected_hl or "PmenuSel")
      vim.api.nvim_set_hl(0, bar_sel_hl, { fg = sel_bg, bg = sel_bg })
      bar_sel_set = true
    end
    return { { thumb_char, bar_sel_hl } }
  end

  return component
end

return M
