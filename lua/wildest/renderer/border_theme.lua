---@mod wildest.renderer.border_theme Border Decoration Utilities
---@brief [[
---Border decoration utilities.
---@brief ]]

local util = require("wildest.util")

local M = {}

--- Border presets: { top-left, top, top-right, left, right, bottom-left, bottom, bottom-right }
local border_presets = {
  single = { "┌", "─", "┐", "│", "│", "└", "─", "┘" },
  double = { "╔", "═", "╗", "║", "║", "╚", "═", "╝" },
  rounded = { "╭", "─", "╮", "│", "│", "╰", "─", "╯" },
  solid = { "█", "▀", "█", "█", "█", "█", "▄", "█" },
}

--- Parse border option into 8-char array
---@param border string|table
---@return table
local function parse_border(border)
  if type(border) == "table" then
    return border
  end
  return border_presets[border] or border_presets["single"]
end

--- Wrap a popupmenu renderer with border decorations
---@param opts table
---@return table border-wrapped renderer options
function M.apply(opts)
  opts = opts or {}

  local border = parse_border(opts.border or "single")
  local border_hl = (opts.highlights and opts.highlights.border) or "WildestBorder"
  local bottom_border_hl = (opts.highlights and opts.highlights.bottom_border) or border_hl
  local content_hl = opts.content_hl or "WildestDefault"

  -- Build native border highlights: border fg on content bg so the frame blends
  local hl_mod = require("wildest.highlight")
  local border_def = vim.api.nvim_get_hl(0, { name = border_hl, link = false })
  local native_hl = hl_mod.make_hl("WildestNativeBorder", content_hl, { fg = border_def.fg })
  local bottom_border_def = vim.api.nvim_get_hl(0, { name = bottom_border_hl, link = false })
  local native_bottom_hl =
    hl_mod.make_hl("WildestNativeBorderBottom", content_hl, { fg = bottom_border_def.fg })

  local left_char = border[4]
  local right_char = border[5]
  local left_w = util.strdisplaywidth(left_char)
  local right_w = util.strdisplaywidth(right_char)

  -- Build native border array for nvim_open_win
  -- Neovim order: TL, T, TR, R, BR, B, BL, L
  -- Preset order:  [1]=TL [2]=T [3]=TR [4]=L [5]=R [6]=BL [7]=B [8]=BR
  local native_border = {
    { border[1], native_hl }, -- TL
    { border[2], native_hl }, -- T
    { border[3], native_hl }, -- TR
    { border[5], native_hl }, -- R  (preset[5])
    { border[8], native_bottom_hl }, -- BR (preset[8])
    { border[7], native_bottom_hl }, -- B  (preset[7])
    { border[6], native_bottom_hl }, -- BL (preset[6])
    { border[4], native_hl }, -- L  (preset[4])
  }

  -- Return decoration info that popupmenu can use
  return {
    border_chars = border,
    border_hl = border_hl,
    bottom_border_hl = bottom_border_hl,
    native_hl = native_hl,
    native_bottom_hl = native_bottom_hl,
    left_char = left_char,
    right_char = right_char,
    left_width = left_w,
    right_width = right_w,
    native_border = native_border,
  }
end

return M
