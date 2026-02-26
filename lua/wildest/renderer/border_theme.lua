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

--- Build a border line (top or bottom), optionally with a centered title
---@param chars table border chars array
---@param width integer total width of the content area
---@param which string 'top' or 'bottom'
---@param title? string optional title to embed in the border
---@return string
local function make_border_line(chars, width, which, title)
  local left_char, mid_char, right_char
  if which == "top" then
    left_char, mid_char, right_char = chars[1], chars[2], chars[3]
  else
    left_char, mid_char, right_char = chars[6], chars[7], chars[8]
  end

  local left_w = util.strdisplaywidth(left_char)
  local right_w = util.strdisplaywidth(right_char)
  local mid_w = util.strdisplaywidth(mid_char)

  local fill_width = width - left_w - right_w
  if fill_width < 0 then
    fill_width = 0
  end

  if title and title ~= "" then
    local padded_title = " " .. title .. " "
    local padded_w = util.strdisplaywidth(padded_title)
    local left_fill_w = 2 * mid_w
    local right_fill_w = fill_width - left_fill_w - padded_w
    if right_fill_w >= mid_w then
      local left_fill = string.rep(mid_char, 2)
      local right_count = math.floor(right_fill_w / mid_w)
      local right_fill = string.rep(mid_char, right_count)
      local remaining = right_fill_w - (right_count * mid_w)
      if remaining > 0 then
        right_fill = right_fill .. string.rep(" ", remaining)
      end
      return left_char .. left_fill .. padded_title .. right_fill .. right_char
    end
  end

  local mid_count = math.floor(fill_width / mid_w)
  local mid_str = string.rep(mid_char, mid_count)
  local remaining = fill_width - (mid_count * mid_w)
  if remaining > 0 then
    mid_str = mid_str .. string.rep(" ", remaining)
  end

  return left_char .. mid_str .. right_char
end

--- Build a prompt border line (separator between prompt and results)
---@param prompt_border table { left, middle, right } characters
---@param width integer total content width
---@return string
local function make_prompt_border_line(prompt_border, width)
  local left_char = prompt_border[1] or ""
  local mid_char = prompt_border[2] or "─"
  local right_char = prompt_border[3] or ""

  local left_w = util.strdisplaywidth(left_char)
  local right_w = util.strdisplaywidth(right_char)
  local mid_w = util.strdisplaywidth(mid_char)

  local fill_width = width - left_w - right_w
  if fill_width < 0 then
    fill_width = 0
  end

  local mid_count = math.floor(fill_width / mid_w)
  local mid_str = string.rep(mid_char, mid_count)
  local remaining = fill_width - (mid_count * mid_w)
  if remaining > 0 then
    mid_str = mid_str .. string.rep(" ", remaining)
  end

  return left_char .. mid_str .. right_char
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
    make_top_line = function(width, title)
      return make_border_line(border, width, "top", title)
    end,
    make_bottom_line = function(width, title)
      return make_border_line(border, width, "bottom", title)
    end,
    make_prompt_border = function(prompt_border, width)
      return make_prompt_border_line(prompt_border, width)
    end,
  }
end

M.parse_border = parse_border
M.make_border_line = make_border_line
M.make_prompt_border_line = make_prompt_border_line
M.border_presets = border_presets

return M
