local themes = require("wildest.themes")

--- Auto theme: derives all colors from the user's active colorscheme
--- Reads Pmenu, PmenuSel, FloatBorder, Search, and other standard groups
--- at apply-time so it adapts to any colorscheme automatically.

--- Safely get a highlight group's resolved attributes
---@param name string
---@return table
local function get_hl(name)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
  if ok and hl then
    return hl
  end
  return {}
end

--- Extract fg or bg as hex string from a highlight group
---@param name string highlight group name
---@param attr string 'fg' or 'bg'
---@return string|nil hex color
local function get_color(name, attr)
  local hl = get_hl(name)
  local val = hl[attr]
  if val then
    return string.format("#%06x", val)
  end
  return nil
end

--- Blend two hex colors
---@param c1 string hex like '#rrggbb'
---@param c2 string hex like '#rrggbb'
---@param t number 0.0 = all c1, 1.0 = all c2
---@return string hex
local function blend(c1, c2, t)
  if not c1 or not c2 then
    return c1 or c2 or "#888888"
  end
  local r1, g1, b1 =
    tonumber(c1:sub(2, 3), 16), tonumber(c1:sub(4, 5), 16), tonumber(c1:sub(6, 7), 16)
  local r2, g2, b2 =
    tonumber(c2:sub(2, 3), 16), tonumber(c2:sub(4, 5), 16), tonumber(c2:sub(6, 7), 16)
  local r = math.floor(r1 + (r2 - r1) * t)
  local g = math.floor(g1 + (g2 - g1) * t)
  local b = math.floor(b1 + (b2 - b1) * t)
  return string.format("#%02x%02x%02x", r, g, b)
end

--- Build the auto theme dynamically from current colorscheme
---@param opts? table { renderer?: string, border?: string }
---@return table theme
local function build(opts)
  opts = opts or {}

  -- Read colors from standard highlight groups
  local pmenu_bg = get_color("Pmenu", "bg") or "#1e1e2e"
  local pmenu_fg = get_color("Pmenu", "fg") or "#cdd6f4"
  local pmenusel_bg = get_color("PmenuSel", "bg") or "#45475a"
  local pmenusel_fg = get_color("PmenuSel", "fg") or "#cdd6f4"
  local normal_bg = get_color("Normal", "bg") or "#1e1e2e"

  -- Accent: try PmenuMatch → Search fg → Statement fg → a warm color
  local accent_fg = get_color("PmenuMatch", "fg")
    or get_color("Search", "fg")
    or get_color("Statement", "fg")
    or get_color("Type", "fg")
    or "#f9e2af"

  local sel_accent_fg = get_color("PmenuMatchSel", "fg")
    or get_color("IncSearch", "fg")
    or accent_fg

  -- Border: try FloatBorder → WinSeparator → blend pmenu bg darker
  local border_fg = get_color("FloatBorder", "fg")
    or get_color("WinSeparator", "fg")
    or blend(pmenu_fg, pmenu_bg, 0.6)
  local border_bg = get_color("FloatBorder", "bg") or blend(pmenu_bg, normal_bg, 0.5)

  -- Cursor: try Cursor → TermCursor → reverse of pmenu
  local cursor_bg = get_color("Cursor", "bg") or get_color("TermCursor", "bg") or accent_fg
  local cursor_fg = get_color("Cursor", "fg") or border_bg

  -- Spinner: use accent
  local spinner_fg = accent_fg

  return themes.define({
    renderer = opts.renderer or "border",
    highlights = {
      WildestDefault = { bg = pmenu_bg, fg = pmenu_fg },
      WildestSelected = { bg = pmenusel_bg, fg = pmenusel_fg, bold = true },
      WildestAccent = { bg = pmenu_bg, fg = accent_fg, bold = true },
      WildestSelectedAccent = {
        bg = pmenusel_bg,
        fg = sel_accent_fg,
        bold = true,
        underline = true,
      },
      WildestBorder = { bg = border_bg, fg = border_fg },
      WildestPrompt = { bg = pmenu_bg, fg = pmenu_fg },
      WildestPromptCursor = { bg = cursor_bg, fg = cursor_fg },
      WildestSpinner = { fg = spinner_fg },
    },
    renderer_opts = {
      border = opts.border or "rounded",
      left = { " " },
      right = { " " },
    },
  })
end

-- The auto theme is a callable table: calling it rebuilds from current colorscheme
-- Accessing .renderer() or .apply() uses a cached build
local auto = {}
local cached = nil

--- Apply the auto theme highlight groups
function auto.apply()
  -- Try compiled bytecode first for instant loading
  if themes.load_compiled("auto") then
    return
  end
  cached = build()
  cached.apply()
end

--- Get a configured renderer using auto-detected theme settings
---@param user_opts? table override options
---@return table renderer
function auto.renderer(user_opts)
  -- Try compiled cache first
  if themes.load_compiled("auto") then
    -- Highlights are applied, just create the renderer
    cached = build(user_opts)
    user_opts = user_opts or {}
    local opts = vim.tbl_deep_extend("force", cached.get_def().renderer_opts or {}, user_opts)
    opts.hl = opts.hl or "WildestDefault"
    opts.selected_hl = opts.selected_hl or "WildestSelected"
    opts.highlights = opts.highlights or {}
    opts.highlights.border = opts.highlights.border or "WildestBorder"
    opts.highlights.bottom_border = opts.highlights.bottom_border or "WildestBorder"
    opts.highlights.prompt = opts.highlights.prompt or "WildestPrompt"
    opts.highlights.prompt_cursor = opts.highlights.prompt_cursor or "WildestPromptCursor"
    return themes.create_renderer(cached.get_def().renderer or "border", opts)
  end
  -- No cache: build fresh from current colorscheme
  cached = build(user_opts)
  return cached.renderer(user_opts)
end

--- Get the auto theme definition
---@return table def
function auto.get_def()
  if not cached then
    cached = build()
  end
  return cached.get_def()
end

--- Rebuild with specific options (renderer type, border style)
---@param opts? table { renderer?: string, border?: string }
---@return table theme
function auto.build(opts)
  return build(opts)
end

return auto
