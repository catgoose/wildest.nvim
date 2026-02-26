---@mod wildest wildest.nvim
---@brief [[
---Fast, pure-Lua cmdline completion engine for Neovim.
---
---wildest.nvim provides fuzzy completion for command-line mode (:), search (/),
---and reverse search (?) with an async pipeline architecture, C FFI fuzzy
---matching, and a composable renderer/component system.
---
---Quickstart:
---
--->lua
---require('wildest').setup({
---  modes = { ':', '/', '?' },
---  pipeline = require('wildest').cmdline_pipeline(),
---  renderer = require('wildest').popupmenu_renderer(),
---})
---<
---@brief ]]

---@toc wildest-contents

---@class wildest
---@field setup fun(opts: wildest.Config)
local branch_mod = require("wildest.pipeline.branch")
local check_mod = require("wildest.pipeline.check")
local config = require("wildest.config")
local debounce_mod = require("wildest.pipeline.debounce")
local log = require("wildest.log")
local result_mod = require("wildest.pipeline.result")
local state = require("wildest.state")
local subpipeline_mod = require("wildest.pipeline.subpipeline")

local M = {}

local augroup = nil

---@tag wildest-setup

---Setup wildest with user config.
---Creates autocommands for CmdlineEnter/Changed/Leave and sets up keybindings.
---@param opts wildest.Config User configuration (merged with defaults)
function M.setup(opts)
  log.clear()
  log.log("setup", "start")

  local cfg = config.setup(opts)
  log.log("setup", "config_done")

  -- Clean up any stale state from previous setup() calls
  require("wildest.pipeline").clear_handlers()
  state.enable()

  -- Create autocommands
  if augroup then
    vim.api.nvim_del_augroup_by_id(augroup)
  end
  augroup = vim.api.nvim_create_augroup("wildest", { clear = true })

  vim.api.nvim_create_autocmd("CmdlineEnter", {
    group = augroup,
    callback = function()
      local cmdtype = vim.fn.getcmdtype()
      log.log("autocmd", "CmdlineEnter", { cmdtype = cmdtype })
      state.start(cmdtype)
    end,
  })

  vim.api.nvim_create_autocmd("CmdlineChanged", {
    group = augroup,
    callback = function()
      local cmdline = vim.fn.getcmdline()
      log.log("autocmd", "CmdlineChanged", { cmdline = cmdline, active = state.is_active() })
      if not state.is_active() then
        return
      end
      state.on_change(cmdline)
    end,
  })

  vim.api.nvim_create_autocmd("CmdlineLeave", {
    group = augroup,
    callback = function()
      log.log("autocmd", "CmdlineLeave")
      state.stop()
      log.flush()
    end,
  })

  -- Set up keybindings
  local function cmap(key, handler)
    vim.keymap.set("c", key, function()
      if handler() then
        return ""
      end
      local raw = vim.api.nvim_replace_termcodes(key, true, false, true)
      vim.api.nvim_feedkeys(raw, "in", false)
      return ""
    end, { noremap = true, silent = true, expr = true })
  end

  local function bind(keys, handler)
    if not keys then
      return
    end
    if type(keys) == "string" then
      keys = { keys }
    end
    for _, key in ipairs(keys) do
      cmap(key, handler)
    end
  end

  bind(cfg.next_key, function()
    if state.is_active() and (state.get().result or not state.get().triggered) then
      state.step(1)
      return true
    end
  end)

  bind(cfg.previous_key, function()
    if state.is_active() and (state.get().result or not state.get().triggered) then
      state.step(-1)
      return true
    end
  end)

  bind(cfg.accept_key, function()
    if state.is_active() and state.get().selected >= 0 then
      state.accept_completion()
      return true
    end
  end)

  bind(cfg.reject_key, function()
    if state.is_active() and state.get().replaced_cmdline then
      state.reject_completion()
      return true
    end
  end)

  bind(cfg.scroll_down_key, function()
    if state.is_active() and state.get().result then
      state.scroll(cfg.scroll_size or 10)
      return true
    end
  end)

  bind(cfg.scroll_up_key, function()
    if state.is_active() and state.get().result then
      state.scroll(-(cfg.scroll_size or 10))
      return true
    end
  end)

  bind(cfg.close_key, function()
    if state.is_active() and state.get().result then
      state.close()
      return true
    end
  end)

  bind(cfg.confirm_key, function()
    if state.is_active() and state.get().selected >= 0 then
      return state.confirm()
    end
  end)

  bind(cfg.dismiss_key, function()
    if state.is_active() and state.get().result then
      state.dismiss()
      return true
    end
  end)

  if cfg.jump_keys then
    for _, entry in ipairs(cfg.jump_keys) do
      local key = entry[1] or entry.key
      local count = entry[2] or entry.count or 1
      bind(key, function()
        if state.is_active() and state.get().result then
          state.scroll(count)
          return true
        end
      end)
    end
  end

  -- If setup() is called while already in cmdline mode (lazy-loading),
  -- start the session immediately so we don't miss CmdlineEnter.
  local cmdtype = vim.fn.getcmdtype()
  log.log("setup", "late_start_check", { cmdtype = cmdtype })
  if cmdtype ~= "" then
    state.start(cmdtype)
    local cmdline = vim.fn.getcmdline()
    if cmdline ~= "" then
      state.on_change(cmdline)
    end
  end
  log.log("setup", "done")
end

---@tag wildest-pipelines
---@divider Pipeline Constructors

---Branch pipeline — tries each sub-pipeline until one succeeds.
---@param ... wildest.Pipeline[] Sub-pipelines to try in order
---@return wildest.PipelineStep
function M.branch(...)
  return branch_mod.branch(...)
end

---Check pipeline — predicate gate that passes input through if predicate returns true.
---@param predicate fun(ctx: wildest.PipelineContext, input: any): boolean
---@return wildest.PipelineStep
function M.check(predicate)
  return check_mod.check(predicate)
end

---Debounce pipeline — delays execution by the given interval.
---@param interval integer Delay in milliseconds
---@return wildest.PipelineStep
function M.debounce(interval)
  return debounce_mod.debounce(interval)
end

---Wrap pipeline output with metadata (highlighter, output transform, etc.).
---@param opts wildest.ResultOpts Result options
---@return wildest.PipelineStep
function M.result(opts)
  return result_mod.result(opts)
end

---Create a dynamic sub-pipeline at runtime from a factory function.
---@param factory fun(ctx: wildest.PipelineContext): wildest.PipelineStep[]
---@return wildest.PipelineStep
function M.subpipeline(factory)
  return subpipeline_mod.subpipeline(factory)
end

---Cmdline pipeline — completes commands, files, buffers, help tags, etc.
---@param opts? wildest.CmdlinePipelineOpts
---@return wildest.PipelineStep[] pipeline
function M.cmdline_pipeline(opts)
  return require("wildest.cmdline").cmdline_pipeline(opts)
end

---Search pipeline — completes search patterns from buffer lines and history.
---@param opts? wildest.SearchPipelineOpts
---@return wildest.PipelineStep[] pipeline
function M.search_pipeline(opts)
  return require("wildest.search").search_pipeline(opts)
end

---File finder pipeline — finds files using fd, rg, or find.
---@param opts? wildest.FileFinderOpts
---@return wildest.PipelineStep[] pipeline
function M.file_finder_pipeline(opts)
  return require("wildest.file_finder").file_finder_pipeline(opts)
end

---Fuzzy filter pipeline step — filters and sorts candidates by fuzzy match score.
---@param opts? wildest.FuzzyFilterOpts
---@return wildest.PipelineStep
function M.fuzzy_filter(opts)
  return require("wildest.filter").fuzzy_filter(opts)
end

---Deduplication filter pipeline step.
---@param opts? wildest.UniqFilterOpts
---@return wildest.PipelineStep
function M.uniq_filter(opts)
  return require("wildest.filter.uniq").uniq_filter(opts)
end

---@divider Pipeline Combinators

---Transform each candidate through a function.
---Return nil from fn to drop the candidate.
---@param fn fun(candidate: any, index: integer, ctx: wildest.PipelineContext): any?
---@return wildest.PipelineStep
function M.map(fn)
  return require("wildest.pipeline.map").map(fn)
end

---Filter candidates with a predicate (true = keep).
---@param fn fun(candidate: any, index: integer, ctx: wildest.PipelineContext): boolean
---@return wildest.PipelineStep
function M.filter(fn)
  return require("wildest.pipeline.filter").filter(fn)
end

---Sort candidates lexically, or with a custom comparator.
---@param comparator? fun(a: any, b: any, ctx: wildest.PipelineContext): boolean
---@return wildest.PipelineStep
function M.sort(comparator)
  return require("wildest.pipeline.sort").sort(comparator)
end

---Sort candidates by a scoring function (highest score first).
---@param scorer fun(candidate: any, ctx: wildest.PipelineContext): number
---@return wildest.PipelineStep
function M.sort_by(scorer)
  return require("wildest.pipeline.sort").sort_by(scorer)
end

---Limit the number of candidates.
---@param n integer Maximum number of candidates
---@return wildest.PipelineStep
function M.take(n)
  return require("wildest.pipeline.take").take(n)
end

---Compose multiple sync pipeline steps into one.
---@param ... wildest.PipelineStep
---@return wildest.PipelineStep
function M.pipe(...)
  return require("wildest.pipeline.pipe").pipe(...)
end

---Wrap an async operation into a pipeline step.
---@param fn fun(ctx: wildest.PipelineContext, input: any, resolve: fun(result: any), reject: fun(err: any))
---@return wildest.PipelineStep
function M.async(fn)
  return require("wildest.pipeline.async").async(fn)
end

---Create a pipeline step from vim.fn.getcompletion().
---@param complete_type string|fun(ctx: wildest.PipelineContext): string Completion type or dynamic selector
---@param opts? table
---@return wildest.PipelineStep
function M.vim_complete(complete_type, opts)
  return require("wildest.pipeline.vim_complete").vim_complete(complete_type, opts)
end

---@divider Domain Pipelines

---History completion pipeline (command and search history).
---@param opts? table
---@return wildest.PipelineStep[] pipeline
function M.history_pipeline(opts)
  return { require("wildest.pipeline.history").history(opts) }
end

---Lua expression completion pipeline (:lua, :=).
---@param opts? table
---@return wildest.PipelineStep[] pipeline
function M.lua_pipeline(opts)
  return require("wildest.pipeline.lua_complete").lua_pipeline(opts)
end

---Help tag completion pipeline.
---@param opts? table
---@return wildest.PipelineStep[] pipeline
function M.help_pipeline(opts)
  return require("wildest.pipeline.help").help_pipeline(opts)
end

---@tag wildest-renderers
---@divider Renderer Constructors

---@class wildest.PopupmenuOpts
---@field highlighter? table Highlighter for match accents
---@field left? table Left components (default { " " })
---@field right? table Right components (default { " " })
---@field max_height? integer Maximum number of visible lines (default 16)
---@field min_height? integer Minimum number of visible lines (default 0)
---@field max_width? integer|nil Maximum width (nil = full editor width)
---@field min_width? integer Minimum width (default 16)
---@field reverse? boolean Reverse candidate order (default false)
---@field fixed_height? boolean Pad to max_height to prevent resizing (default false)
---@field pumblend? integer Window transparency 0-100
---@field zindex? integer Floating window z-index (default 250)

---@class wildest.PopupmenuBorderOpts
---@field border? string|table Border style preset or 8-char array (default "single")
---@field title? string Title centered in the top border
---@field highlighter? table Highlighter for match accents
---@field left? table Left components (default { " " })
---@field right? table Right components (default { " " })
---@field max_height? integer|string Max visible lines, integer or percentage (default 16)
---@field min_height? integer Minimum visible lines (default 0)
---@field max_width? integer|string|nil Max width, integer or percentage (nil = full width)
---@field min_width? integer|string Minimum width, integer or percentage (default 16)
---@field reverse? boolean Reverse candidate order (default false)
---@field fixed_height? boolean Pad to max_height to prevent resizing (default false)
---@field position? string Vertical placement: "top", "center", or "bottom" (default "bottom")
---@field empty_message? string Message shown when there are no results
---@field pumblend? integer Window transparency 0-100
---@field zindex? integer Floating window z-index (default 250)

---@class wildest.PopupmenuPaletteOpts
---@field border? string|table Border style preset or 8-char array (default "rounded")
---@field title? string Title centered in the top border
---@field prompt_prefix? string Prefix shown before cmdline input (default " : ")
---@field prompt_position? string Prompt placement: "top" or "bottom" (default "top")
---@field highlighter? table Highlighter for match accents
---@field left? table Left components (default { " " })
---@field right? table Right components (default { " " })
---@field max_height? string|integer Max height, percentage or integer (default "75%")
---@field min_height? integer Minimum height (default 0)
---@field max_width? string|integer Max width, percentage or integer (default "75%")
---@field min_width? integer|string Minimum width (default 30)
---@field margin? string|integer Horizontal margin: "auto", percentage, or integer (default "auto")
---@field reverse? boolean Reverse candidate order (default false)
---@field fixed_height? boolean Pad to max_height to prevent resizing (default false)
---@field empty_message? string Message shown when there are no results
---@field pumblend? integer Window transparency 0-100
---@field zindex? integer Floating window z-index (default 250)

---Popupmenu renderer — floating window above the cmdline.
---@param opts? wildest.PopupmenuOpts
---@return wildest.Renderer
function M.popupmenu_renderer(opts)
  return require("wildest.renderer.popupmenu").new(opts)
end

---Popupmenu with border theme — decorative border around the popup.
---@param opts? wildest.PopupmenuBorderOpts
---@return wildest.Renderer
function M.popupmenu_border_theme(opts)
  return require("wildest.renderer.popupmenu_border").new(opts)
end

---Popupmenu palette theme — centered, bordered popup with prompt.
---@param opts? wildest.PopupmenuPaletteOpts
---@return wildest.Renderer
function M.popupmenu_palette_theme(opts)
  return require("wildest.renderer.popupmenu_palette").new(opts)
end

---Wildmenu renderer — horizontal completion in the statusline area.
---@param opts? wildest.WildmenuOpts
---@return wildest.Renderer
function M.wildmenu_renderer(opts)
  return require("wildest.renderer.wildmenu").new(opts)
end

---Renderer mux — route to different renderers by cmdtype.
---@param routes table<string, wildest.Renderer> Map of cmdtype to renderer
---@return wildest.Renderer
function M.renderer_mux(routes)
  return require("wildest.renderer.mux").new(routes)
end

---@tag wildest-highlighters
---@divider Highlighter Constructors

---Basic subsequence highlighter.
---@param opts? table
---@return wildest.Highlighter
function M.basic_highlighter(opts)
  return require("wildest.highlight.basic").new(opts)
end

---Fzy C FFI highlighter — uses fuzzy_positions for accurate match highlighting.
---@param opts? table
---@return wildest.Highlighter
function M.fzy_highlighter(opts)
  return require("wildest.highlight.fzy").new(opts)
end

---Prefix highlighter — highlights the leading prefix that matches the query.
---@param opts? table
---@return wildest.Highlighter
function M.prefix_highlighter(opts)
  return require("wildest.highlight.prefix").new(opts)
end

---Gradient highlighter — wraps another highlighter with per-character color gradient.
---@param base_highlighter wildest.Highlighter
---@param gradient string[] Array of highlight group names for the gradient
---@param opts? { selected_gradient?: string[] }
---@return wildest.Highlighter
function M.gradient_highlighter(base_highlighter, gradient, opts)
  return require("wildest.highlight.gradient").new(base_highlighter, gradient, opts)
end

---@tag wildest-components
---@divider Component Constructors

---Scrollbar component for popupmenu renderers.
---@param opts? table
---@return wildest.Component
function M.popupmenu_scrollbar(opts)
  return require("wildest.renderer.components.scrollbar").new(opts)
end

---Loading spinner component for popupmenu renderers.
---@param opts? table
---@return wildest.Component
function M.popupmenu_spinner(opts)
  return require("wildest.renderer.components.spinner").new(opts)
end

---File type icon component (requires nvim-web-devicons).
---@param opts? table
---@return wildest.Component
function M.popupmenu_devicons(opts)
  return require("wildest.renderer.components.devicons").new(opts)
end

---Buffer flags component (modified, readonly, etc.).
---@param opts? table
---@return wildest.Component
function M.popupmenu_buffer_flags(opts)
  return require("wildest.renderer.components.buffer_flags").new(opts)
end

---Empty message with animated spinner.
---@param opts? table
---@return wildest.Component
function M.popupmenu_empty_message_with_spinner(opts)
  return require("wildest.renderer.components.empty_message_with_spinner").new(opts)
end

---Zip columns — merge two column components with a custom function.
---@param merger fun(a: table, b: table): table
---@param col1 wildest.Component
---@param col2 wildest.Component
---@return wildest.Component
function M.popupmenu_zip_columns(merger, col1, col2)
  return require("wildest.renderer.components.zip_columns").new(merger, col1, col2)
end

---Previous/next arrow indicators for wildmenu.
---@param opts? table
---@return wildest.Component
function M.wildmenu_arrows(opts)
  return require("wildest.renderer.components.arrows").new(opts)
end

---Separator component for wildmenu items.
---@param opts? table
---@return wildest.Component
function M.wildmenu_separator(opts)
  return require("wildest.renderer.components.separator").new(opts)
end

---Position indicator (X/Y) for wildmenu.
---@param opts? table
---@return wildest.Component
function M.wildmenu_index(opts)
  return require("wildest.renderer.components.index").new(opts)
end

---Conditional component — shows if_true or if_false based on predicate.
---@param predicate fun(ctx: table): boolean
---@param if_true wildest.Component
---@param if_false? wildest.Component
---@return wildest.Component
function M.condition(predicate, if_true, if_false)
  return require("wildest.renderer.components.condition").new(predicate, if_true, if_false)
end

---Kind/type icon component for popupmenu renderers.
---@param opts? table
---@return wildest.Component
function M.popupmenu_kind_icon(opts)
  return require("wildest.renderer.components.kind_icon").new(opts)
end

---Static empty message component.
---@param msg string Message to display when there are no results
---@param hl? string Highlight group
---@return wildest.Component
function M.empty_message(msg, hl)
  return require("wildest.renderer.components.empty_message").new(msg, hl)
end

---@divider Utilities

---Create or update a highlight group by extending a base group.
---@param name string New highlight group name
---@param base string Base highlight group to extend
---@param overrides table Highlight attributes to override
---@return string name The highlight group name
function M.make_hl(name, base, overrides)
  return require("wildest.highlight").make_hl(name, base, overrides)
end

---Create a highlight group with additional boolean attributes (bold, italic, etc.).
---@param name string New highlight group name
---@param base string Base highlight group
---@param ... string Attribute names (e.g., 'bold', 'underline', 'italic')
---@return string name The highlight group name
function M.hl_with_attr(name, base, ...)
  return require("wildest.highlight").hl_with_attr(name, base, ...)
end

---Project root detection — returns a function that finds the project root.
---@param markers? string[] Root markers (default: { '.git', '.hg' })
---@return fun(path: string): string
function M.project_root(markers)
  return function(path)
    return require("wildest.util").project_root(markers, path)
  end
end

---Clear the project root detection cache.
function M.clear_project_root_cache()
  require("wildest.util").clear_project_root_cache()
end

---Frecency scorer — for use with sort_by to rank by frequency + recency.
---@param opts? table { weights?: table }
---@return fun(candidate: string, ctx: table): number
function M.frecency_scorer(opts)
  return require("wildest.frecency").scorer(opts)
end

---Frecency boost — pipeline step that re-sorts candidates by frecency.
---@param opts? table { weights?: table, blend?: number }
---@return wildest.PipelineStep
function M.frecency_boost(opts)
  return require("wildest.frecency").boost(opts)
end

---Record a frecency visit for an item.
---@param key string The item key
function M.frecency_visit(key)
  require("wildest.frecency").visit(key)
end

---@tag wildest-themes
---@divider Themes

---Get a built-in theme by name.
---Available: 'auto', 'default', 'saloon', 'outlaw', 'sunset', 'prairie',
---'dusty', 'midnight', 'wanted', 'cactus', 'tumbleweed',
---'kanagawa', 'kanagawa_dragon', 'kanagawa_lotus'
---@param name string Theme name
---@return wildest.Theme theme Theme object
function M.theme(name)
  local themes = require("wildest.themes")
  local t = themes[name]
  if not t then
    vim.notify("[wildest] Unknown theme: " .. name, vim.log.levels.WARN)
    return themes.default
  end
  return t
end

---Define a custom theme.
---@param def wildest.ThemeDef Theme definition
---@return wildest.Theme theme
function M.define_theme(def)
  return require("wildest.themes").define(def)
end

---Extend an existing theme with overrides.
---@param base wildest.Theme|string Base theme object or name
---@param overrides wildest.ThemeDef Partial definition to merge
---@return wildest.Theme theme
function M.extend_theme(base, overrides)
  if type(base) == "string" then
    base = M.theme(base)
  end
  return require("wildest.themes").extend(base, overrides)
end

---Compile a theme to bytecode for instant loading.
---For 'auto', this snapshots your current colorscheme's colors.
---@param name string Theme name
function M.compile_theme(name)
  require("wildest.themes").compile(name)
end

---Compile all built-in themes to bytecode.
function M.compile_all_themes()
  require("wildest.themes").compile_all()
end

---Load a compiled theme from bytecode cache.
---@param name string Theme name
---@return boolean success True if compiled theme was found and loaded
function M.load_compiled_theme(name)
  return require("wildest.themes").load_compiled(name)
end

---Clear all compiled theme bytecode caches.
function M.clear_theme_cache()
  require("wildest.themes").clear_cache()
end

---@divider State Control

---Enable wildest completions.
function M.enable()
  state.enable()
end

---Disable wildest completions.
function M.disable()
  state.disable()
end

---Toggle wildest completions on/off.
function M.toggle()
  state.toggle()
end

return M
