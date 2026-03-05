---@mod wildest.renderer.components.cmdline_icon Cmdline Icon Component
---@brief [[
---Context-aware icon component that shows a single icon based on the current
---cmdline command type (file, help, lua, search, etc.), not per-candidate.
---Inspired by noice.nvim's per-command-pattern styling.
---@brief ]]

local BaseComponent = require("wildest.renderer.components.base")
local M = {}

local default_icons = {
  file = " ",
  dir = " ",
  buffer = " ",
  help = "󰋖 ",
  option = " ",
  color = " ",
  highlight = " ",
  command = " ",
  lua = " ",
  search = " ",
  substitute = " ",
  shell = " ",
  environment = " ",
  filetype = " ",
  event = " ",
  ["function"] = "󰊕 ",
  default = " ",
}

--- Determine the icon key from pipeline result data and cmdtype.
---@param data table pipeline result data
---@param cmdtype string|nil
---@return string icon_key
local function resolve_key(data, cmdtype)
  if cmdtype == "/" or cmdtype == "?" then
    return "search"
  end

  local expand = data.expand or ""
  local cmd = data.cmd or ""

  if expand == "file" or expand == "file_in_path" or expand == "dir" then
    return expand == "dir" and "dir" or "file"
  elseif expand == "buffer" then
    return "buffer"
  elseif expand == "help" then
    return "help"
  elseif expand == "option" then
    return "option"
  elseif expand == "color" then
    return "color"
  elseif expand == "highlight" then
    return "highlight"
  elseif expand == "lua" or expand == "expression" then
    return "lua"
  elseif expand == "shellcmd" then
    return "shell"
  elseif expand == "environment" then
    return "environment"
  elseif expand == "filetype" then
    return "filetype"
  elseif expand == "event" then
    return "event"
  elseif expand == "function" or expand == "user_func" then
    return "function"
  end

  -- Check command name for patterns not captured by expand type
  if cmd:match("^s/") or cmd:match("^%%s/") or cmd:match("^g/") then
    return "substitute"
  end
  if cmd:match("^!") then
    return "shell"
  end

  if expand == "command" or expand == "user_commands" then
    return "command"
  end

  return "default"
end

--- Create a cmdline icon component.
---@param opts? table { icons?: table<string,string>, hl?: string|table<string,string> }
---@return table component
function M.new(opts)
  opts = opts or {}
  local icons = vim.tbl_extend("force", default_icons, opts.icons or {})
  local hl_opt = opts.hl or "WildestCmdlineIcon"

  pcall(vim.api.nvim_set_hl, 0, "WildestCmdlineIcon", { link = "Special", default = true })

  local component = setmetatable({}, { __index = BaseComponent })

  function component:render(ctx)
    local data = (ctx.result and ctx.result.data) or {}
    local cmdtype = vim.fn.getcmdtype()
    local key = resolve_key(data, cmdtype)
    local icon = icons[key] or icons.default

    local hl_group
    if type(hl_opt) == "table" then
      hl_group = hl_opt[key] or hl_opt.default or "WildestCmdlineIcon"
    else
      hl_group = hl_opt
    end

    return { { icon, hl_group } }
  end

  return component
end

return M
