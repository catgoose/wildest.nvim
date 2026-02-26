---@mod wildest.renderer.components.kind_icon Kind/Type Icon Component
---@brief [[
---Kind/type icon component for popupmenu renderers.
---Shows an icon based on the completion kind or file type of each candidate.
---@brief ]]

local M = {}

-- Default kind icons (LSP CompletionItemKind style)
local default_icons = {
  Text = " ",
  Method = " ",
  Function = "󰊕 ",
  Constructor = " ",
  Field = " ",
  Variable = "󰀫 ",
  Class = " ",
  Interface = " ",
  Module = " ",
  Property = " ",
  Unit = " ",
  Value = "󰎠 ",
  Enum = " ",
  Keyword = " ",
  Snippet = " ",
  Color = " ",
  File = " ",
  Reference = " ",
  Folder = " ",
  EnumMember = " ",
  Constant = " ",
  Struct = " ",
  Event = " ",
  Operator = " ",
  TypeParameter = " ",
  -- Command-line specific
  Command = " ",
  Option = " ",
  Help = "󰋖 ",
  Buffer = " ",
  Colorscheme = " ",
  Keymap = " ",
  Mark = " ",
  Register = " ",
}

--- Create a kind icon component
---@param opts? table { icons?: table<string,string>, default?: string, hl?: string, kind_fn?: fun(candidate: string, ctx: table): string? }
---@return table component
function M.new(opts)
  opts = opts or {}
  local icons = vim.tbl_extend("force", default_icons, opts.icons or {})
  local default_icon = opts.default or "  "
  local hl_group = opts.hl or "WildestKindIcon"
  local kind_fn = opts.kind_fn

  pcall(vim.api.nvim_set_hl, 0, "WildestKindIcon", { link = "Special" })

  local component = {}

  function component:render(ctx)
    local candidate = ctx.candidate or ""
    local kind = nil

    if kind_fn then
      kind = kind_fn(candidate, ctx)
    end

    local icon = (kind and icons[kind]) or default_icon
    return { { icon, hl_group } }
  end

  return component
end

return M
