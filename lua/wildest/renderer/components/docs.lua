---@mod wildest.renderer.components.docs Documentation Hints Component
---@brief [[
---Bottom chrome component that shows a one-line documentation hint for the
---currently selected completion candidate. Extracts info from Neovim's help
---system, option metadata, command registry, and highlight definitions.
---@brief ]]

local docs = require("wildest.docs")

local M = {}

--- Create a documentation hints chrome component.
--- Use in the `bottom` array of a popupmenu renderer.
---
--- Example:
---   bottom = { w.popupmenu_docs() }
---
---@param opts? table { hl?: string, prefix?: string }
---@return function chrome_component
function M.new(opts)
  opts = opts or {}
  local hl = opts.hl or "WildestDocs"
  local prefix = opts.prefix or " "

  pcall(vim.api.nvim_set_hl, 0, "WildestDocs", { link = "Comment", default = true })

  return function(ctx)
    if ctx.selected < 0 then
      return nil
    end

    local result = ctx.result
    if not result or not result.value then
      return nil
    end

    local candidates = result.value
    local candidate = candidates[ctx.selected + 1]
    if not candidate or candidate == "" then
      return nil
    end

    -- If result has a draw function, the displayed text differs from the raw
    -- candidate. Use the raw candidate for doc lookup.
    local data = result.data or {}
    local expand = data.expand or ""
    local cmd = data.cmd or ""

    local doc = docs.lookup(candidate, expand, cmd)
    if not doc then
      return nil
    end

    local text = prefix .. doc
    -- Truncate to width
    local text_w = vim.api.nvim_strwidth(text)
    if text_w > ctx.width then
      -- Byte-truncate to fit
      local truncated = ""
      local dw = 0
      for _, ch in vim.iter(vim.fn.split(text, "\\zs")):enumerate() do
        local chw = vim.api.nvim_strwidth(ch)
        if dw + chw > ctx.width - 3 then
          break
        end
        truncated = truncated .. ch
        dw = dw + chw
      end
      text = truncated .. "..."
    end

    return { { text, hl } }
  end
end

return M
