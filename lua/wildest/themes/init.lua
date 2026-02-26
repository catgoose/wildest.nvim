---@mod wildest.themes Theme system and compilation
---@brief [[
---Theme system and compilation.
---@brief ]]

local hl_mod = require("wildest.highlight")

local M = {}

--- Canonical list of built-in theme names
M.theme_names = {
  "auto",
  "default",
  "saloon",
  "outlaw",
  "sunset",
  "prairie",
  "dusty",
  "midnight",
  "wanted",
  "cactus",
  "tumbleweed",
  "kanagawa",
  "kanagawa_dragon",
  "kanagawa_lotus",
  "catppuccin_mocha",
  "catppuccin_frappe",
  "catppuccin_latte",
  "tokyonight_night",
  "tokyonight_storm",
  "tokyonight_moon",
  "rose_pine",
  "rose_pine_moon",
  "rose_pine_dawn",
  "gruvbox_dark",
  "gruvbox_light",
  "nord",
  "onedark",
  "nightfox",
  "everforest_dark",
  "everforest_light",
  "dracula",
}

--- Get the compile cache directory
---@return string
local function get_cache_dir()
  local state = vim.fn.stdpath("state")
  return state .. "/wildest"
end

--- Get the compiled file path for a theme
---@param name string theme name
---@return string
local function get_compiled_path(name)
  return get_cache_dir() .. "/" .. name .. "_compiled"
end

--- Apply a set of highlight definitions
---@param defs table<string, table> map of hl group name → attributes
local function apply_highlights(defs)
  for name, attrs in pairs(defs) do
    if attrs.link then
      vim.api.nvim_set_hl(0, name, { link = attrs.link })
    else
      vim.api.nvim_set_hl(0, name, attrs)
    end
  end
end

--- Serialize a highlight attribute table to a Lua code string
---@param attrs table
---@return string
local function serialize_hl_attrs(attrs)
  local parts = {}
  -- Sort keys for deterministic output
  local keys = {}
  for k in pairs(attrs) do
    table.insert(keys, k)
  end
  table.sort(keys)
  for _, k in ipairs(keys) do
    local v = attrs[k]
    if type(v) == "string" then
      table.insert(parts, k .. '="' .. v .. '"')
    elseif type(v) == "boolean" then
      table.insert(parts, k .. "=" .. tostring(v))
    elseif type(v) == "number" then
      table.insert(parts, k .. "=" .. tostring(v))
    end
  end
  return "{" .. table.concat(parts, ",") .. "}"
end

--- Create a renderer by type name
---@param renderer_type string "palette", "border", or "popupmenu"
---@param opts table renderer options
---@return table renderer
function M.create_renderer(renderer_type, opts)
  if renderer_type == "palette" then
    return require("wildest.renderer.popupmenu_palette").new(opts)
  elseif renderer_type == "border" then
    return require("wildest.renderer.popupmenu_border").new(opts)
  else
    return require("wildest.renderer.popupmenu").new(opts)
  end
end

--- Create a theme from a definition table
--- A theme definition contains:
---   highlights: table of highlight group definitions
---   border: border style string or table
---   renderer: 'popupmenu' | 'border' | 'palette'
---   renderer_opts: additional renderer options
---
---@param def table theme definition
---@return table theme object with :apply() and :renderer() methods
function M.define(def)
  local theme = {}

  --- Apply the theme's highlight groups
  function theme.apply()
    if def.highlights then
      apply_highlights(def.highlights)
    end
  end

  --- Get a configured renderer using this theme's settings
  ---@param user_opts? table override options
  ---@return table renderer
  function theme.renderer(user_opts)
    theme.apply()
    user_opts = user_opts or {}

    local opts = vim.tbl_deep_extend("force", def.renderer_opts or {}, user_opts)

    -- Apply theme highlight names
    if def.highlights then
      if def.highlights.WildestDefault and not opts.hl then
        opts.hl = "WildestDefault"
      end
      if def.highlights.WildestSelected and not opts.selected_hl then
        opts.selected_hl = "WildestSelected"
      end
      if def.highlights.WildestBorder then
        opts.highlights = opts.highlights or {}
        opts.highlights.border = opts.highlights.border or "WildestBorder"
        opts.highlights.bottom_border = opts.highlights.bottom_border or "WildestBorder"
      end
      if def.highlights.WildestPrompt then
        opts.highlights = opts.highlights or {}
        opts.highlights.prompt = opts.highlights.prompt or "WildestPrompt"
        opts.highlights.prompt_cursor = opts.highlights.prompt_cursor or "WildestPromptCursor"
      end
    end

    return M.create_renderer(def.renderer or "border", opts)
  end

  --- Get theme definition (for inspection/extending)
  function theme.get_def()
    return def
  end

  return theme
end

--- Extend an existing theme with overrides
---@param base table base theme (from M.define)
---@param overrides table partial definition to merge
---@return table new theme
function M.extend(base, overrides)
  local base_def = base.get_def()
  local new_def = vim.tbl_deep_extend("force", vim.deepcopy(base_def), overrides)
  return M.define(new_def)
end

--- Compile a theme to bytecode for fast loading
--- Generates a Lua function that calls nvim_set_hl() with hardcoded values,
--- dumps it to bytecode, and writes to the Neovim state directory.
---
--- For the 'auto' theme, this snapshots the current colorscheme's colors
--- so they load instantly next time without re-reading highlight groups.
---
---@param name string theme name (e.g., 'saloon', 'auto', 'kanagawa')
function M.compile(name)
  -- Load the theme
  local ok, theme = pcall(require, "wildest.themes." .. name)
  if not ok or not theme then
    vim.notify("[wildest] Unknown theme: " .. name, vim.log.levels.ERROR)
    return
  end

  -- For the auto theme, we need to build it first to resolve live colors
  local def
  if theme.build then
    -- Auto theme: build() resolves colors from current colorscheme
    local built = theme.build()
    def = built.get_def()
  else
    def = theme.get_def()
  end

  if not def or not def.highlights then
    vim.notify("[wildest] Theme has no highlights to compile: " .. name, vim.log.levels.WARN)
    return
  end

  -- Generate Lua code that applies all highlights
  local lines = {
    "local S=vim.api.nvim_set_hl",
  }

  -- Sort group names for deterministic output
  local groups = {}
  for group_name in pairs(def.highlights) do
    table.insert(groups, group_name)
  end
  table.sort(groups)

  for _, group_name in ipairs(groups) do
    local attrs = def.highlights[group_name]
    table.insert(lines, 'S(0,"' .. group_name .. '",' .. serialize_hl_attrs(attrs) .. ")")
  end

  local code = table.concat(lines, "\n")

  -- Validate the generated code
  local func, err = loadstring(code)
  if not func then
    vim.notify(
      "[wildest] Compile error for theme " .. name .. ": " .. tostring(err),
      vim.log.levels.ERROR
    )
    return
  end

  -- Dump to bytecode
  local bytecode = string.dump(func)

  -- Ensure cache directory exists
  local cache_dir = get_cache_dir()
  vim.fn.mkdir(cache_dir, "p")

  -- Write bytecode
  local path = get_compiled_path(name)
  local file = io.open(path, "wb")
  if not file then
    vim.notify("[wildest] Failed to write compiled theme: " .. path, vim.log.levels.ERROR)
    return
  end
  file:write(bytecode)
  file:close()

  vim.notify("[wildest] Compiled theme: " .. name .. " -> " .. path)
end

--- Load a compiled theme from bytecode cache
--- Returns true if successfully loaded, false if no cache exists.
---@param name string theme name
---@return boolean
function M.load_compiled(name)
  local path = get_compiled_path(name)
  local func = loadfile(path)
  if not func then
    return false
  end

  local ok, err = pcall(func)
  if not ok then
    vim.notify("[wildest] Error loading compiled theme: " .. tostring(err), vim.log.levels.WARN)
    return false
  end

  return true
end

--- Compile all built-in themes
function M.compile_all()
  for _, name in ipairs(M.theme_names) do
    M.compile(name)
  end
end

--- Clear all compiled theme caches
function M.clear_cache()
  local cache_dir = get_cache_dir()
  local ok, entries = pcall(vim.fn.readdir, cache_dir)
  if not ok or not entries then
    return
  end

  for _, entry in ipairs(entries) do
    if entry:match("_compiled$") then
      os.remove(cache_dir .. "/" .. entry)
    end
  end
  vim.notify("[wildest] Cleared compiled theme cache")
end

-- Load built-in themes lazily
setmetatable(M, {
  __index = function(_, key)
    local ok, theme = pcall(require, "wildest.themes." .. key)
    if ok then
      return theme
    end
    return nil
  end,
})

return M
