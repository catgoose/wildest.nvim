---@mod wildest.renderer.components.devicons File Type Icon Component
---@brief [[
---File type icon component.
---@brief ]]

local BaseComponent = require("wildest.renderer.components.base")
local M = {}

--- Create a devicons component for the popupmenu
--- Requires nvim-web-devicons
---@param opts? table { default_icon?: string, default_hl?: string }
---@return table component
function M.new(opts)
  opts = opts or {}
  local default_icon = opts.default_icon or " "
  local default_hl = opts.default_hl

  local has_devicons, devicons = pcall(require, "nvim-web-devicons")

  local component = setmetatable({}, { __index = BaseComponent })

  function component:render(ctx)
    local candidate = ""
    if ctx.result and ctx.result.value and ctx.index ~= nil then
      candidate = ctx.result.value[ctx.index + 1] or ""
    end

    if not has_devicons then
      return { { default_icon .. " ", default_hl } }
    end

    -- Extract filename/extension
    local filename = vim.fn.fnamemodify(candidate, ":t")
    local ext = vim.fn.fnamemodify(candidate, ":e")

    local icon, icon_hl = devicons.get_icon(filename, ext, { default = true })
    if not icon then
      icon = default_icon
      icon_hl = default_hl
    end

    return { { icon .. " ", icon_hl or default_hl } }
  end

  return component
end

return M
