-- Declarative screenshot configurations for wildest.nvim
--
-- Each config is a plain table that overrides M.defaults.
-- M.build(name_or_table, w) resolves a config into { pipeline, renderer }.

local M = {}

-- ── Setup ────────────────────────────────────────────────────────

function M.setup(root)
  vim.opt.rtp:prepend(root)

  local devicons_path = root .. "/deps/nvim-web-devicons"
  if vim.fn.isdirectory(devicons_path) == 1 then
    vim.opt.rtp:prepend(devicons_path)
  end

  local kanagawa_paths = {
    root .. "/deps/kanagawa.nvim",
    vim.fn.expand("~/.local/share/nvim/lazy/kanagawa.nvim"),
  }
  for _, kanagawa_path in ipairs(kanagawa_paths) do
    if vim.fn.isdirectory(kanagawa_path) == 1 then
      vim.opt.rtp:prepend(kanagawa_path)
      break
    end
  end

  vim.o.swapfile = false
  vim.o.shadafile = "NONE"
  vim.o.number = true
  vim.o.relativenumber = true
  vim.o.signcolumn = "yes"
  vim.o.termguicolors = true
  vim.o.showmode = false
  vim.o.ruler = false
  vim.o.laststatus = 3
  vim.o.cmdheight = 1
  vim.o.cursorline = true
  vim.o.scrolloff = 8
  vim.o.incsearch = true
  vim.o.hlsearch = true

  local ok = pcall(vim.cmd, "colorscheme kanagawa")
  if not ok then
    vim.cmd("colorscheme habamax")
  end

  M._has_devicons = pcall(require, "nvim-web-devicons")

  math.randomseed(os.time() + vim.fn.getpid())
end

-- ── Defaults ─────────────────────────────────────────────────────

M.defaults = {
  pipeline = { "cmdline_fuzzy", "search" },
  renderer = "theme:auto",
  highlighter = "fzy",
  highlights = { accent = "IncSearch", selected_accent = "IncSearch" },
  left = "devicons",
  right = { " ", "scrollbar" },
  laststatus = 3,
  cmdheight = 1,
}

-- ── Shared data ──────────────────────────────────────────────────

local rainbow_colors = {
  "#ff0000", "#ff4400", "#ff8800", "#ffcc00",
  "#ffff00", "#88ff00", "#00ff44", "#00ffaa",
  "#00ffff", "#00aaff", "#0044ff", "#4400ff",
  "#8800ff", "#cc00ff", "#ff00ff", "#ff0088",
}

local neon_highlights = {
  WildestDefault = { bg = "#0d0d1a", fg = "#e0e0ff" },
  WildestSelected = { bg = "#1a0a2e", fg = "#ffffff", bold = true },
  WildestAccent = { bg = "#0d0d1a", fg = "#00ffcc", bold = true },
  WildestSelectedAccent = { bg = "#1a0a2e", fg = "#ff00ff", bold = true },
  WildestBorder = { bg = "#0d0d1a", fg = "#6644ff" },
  WildestScrollbar = { bg = "#0d0d1a" },
  WildestScrollbarThumb = { bg = "#6644ff" },
}

local ember_highlights = {
  WildestDefault = { bg = "#1a0f0a", fg = "#e8c8a0" },
  WildestSelected = { bg = "#2d1810", fg = "#ffe0b0", bold = true },
  WildestAccent = { bg = "#1a0f0a", fg = "#ff6622", bold = true },
  WildestSelectedAccent = { bg = "#2d1810", fg = "#ffaa44", bold = true },
  WildestBorder = { bg = "#120a06", fg = "#884422" },
  WildestScrollbar = { bg = "#1a0f0a" },
  WildestScrollbarThumb = { bg = "#884422" },
}

local ocean_highlights = {
  WildestDefault = { bg = "#0a1520", fg = "#b0d0e8" },
  WildestSelected = { bg = "#102030", fg = "#d0e8ff", bold = true },
  WildestAccent = { bg = "#0a1520", fg = "#00bbdd", bold = true },
  WildestSelectedAccent = { bg = "#102030", fg = "#44ddff", bold = true },
  WildestBorder = { bg = "#061018", fg = "#226688" },
  WildestScrollbar = { bg = "#0a1520" },
  WildestScrollbarThumb = { bg = "#226688" },
}

-- ── Configs ──────────────────────────────────────────────────────

M.configs = {
  -- Renderer configs
  popupmenu = {
    category = "renderer",
    label = "Popupmenu",
    renderer = "popupmenu",
    highlighter = "basic",
    left = { " " },
  },

  popupmenu_border = {
    category = "renderer",
    label = "Bordered",
  },

  popupmenu_palette = {
    category = "renderer",
    label = "Palette",
    renderer = "palette",
    palette = {
      title = " Wildest ",
      prompt_prefix = " : ",
      prompt_position = "top",
      max_height = "60%",
      max_width = "60%",
      min_width = 40,
      margin = "auto",
    },
    left = { " " },
  },

  wildmenu = {
    category = "renderer",
    label = "Wildmenu",
    renderer = "wildmenu",
    highlighter = "basic",
    separator = " | ",
    left = { "arrows" },
    right = { "arrows_right", " ", "index" },
  },

  -- Feature configs
  devicons = {
    category = "feature",
    cmd = ":e lua/wildest/",
    left = { " ", "devicons" },
  },

  fuzzy = {
    category = "feature",
    cmd = ":help win",
    left = { " " },
  },

  gradient = {
    category = "feature",
    cmd = ":help help-",
    highlights = false,
    highlighter = "gradient",
    gradient_colors = rainbow_colors,
    left = { " " },
  },

  search = {
    category = "feature",
    cmd = "/function",
    highlighter = "basic",
    left = { " " },
  },

  renderer_mux = {
    category = "feature",
    renderer = "mux",
    mux = {
      [":"] = {
        renderer = "theme:auto",
        highlighter = "fzy",
        highlights = { accent = "IncSearch", selected_accent = "IncSearch" },
        left = "devicons",
        right = { " ", "scrollbar" },
      },
      ["/"] = {
        renderer = "wildmenu",
        highlighter = "basic",
        highlights = { accent = "IncSearch", selected_accent = "IncSearch" },
        separator = " | ",
      },
    },
  },

  kind_icons = {
    category = "feature",
    left = { " ", "kind_icon" },
  },

  -- Pipeline configs
  lua_pipeline = {
    category = "pipeline",
    label = "Lua Completion",
    cmd = ":lua vim.api.nvim",
    pipeline = { "lua", "cmdline_fuzzy" },
  },

  help_pipeline = {
    category = "pipeline",
    label = "Help Tags",
    cmd = ":help nvim_b",
    pipeline = { "help_fuzzy", "cmdline_fuzzy" },
  },

  history_pipeline = {
    category = "pipeline",
    label = "History",
    pipeline = { "history", "cmdline_fuzzy" },
    left = { " " },
  },

  -- Layout configs (statusline / offset variations)
  laststatus_0 = {
    category = "layout",
    label = "laststatus=0",
    laststatus = 0,
  },

  laststatus_2 = {
    category = "layout",
    label = "laststatus=2",
    laststatus = 2,
  },

  laststatus_3 = {
    category = "layout",
    label = "laststatus=3",
    laststatus = 3,
  },

  cmdheight_0 = {
    category = "layout",
    label = "cmdheight=0",
    cmdheight = 0,
  },

  cmdheight_0_offset_1 = {
    category = "layout",
    label = "cmdheight=0 offset=1",
    cmdheight = 0,
    offset = 1,
  },

  cmdheight_0_offset_2 = {
    category = "layout",
    label = "cmdheight=0 offset=2",
    cmdheight = 0,
    offset = 2,
  },

  offset_1 = {
    category = "layout",
    label = "offset=1",
    offset = 1,
  },

  offset_2 = {
    category = "layout",
    label = "offset=2",
    offset = 2,
  },

  -- Renderer option configs
  noselect_false = {
    category = "option",
    label = "noselect=false",
    noselect = false,
  },

  reverse = {
    category = "option",
    label = "reverse=true",
    reverse = true,
  },

  empty_message = {
    category = "option",
    cmd = ":zzzznotacommand",
    renderer = "border_theme",
    border = "rounded",
    empty_message = " No matches, partner ",
  },

  buffer_flags = {
    category = "option",
    cmd = ":b ",
    pipeline = { "cmdline_fuzzy" },
    left = { " ", "buffer_flags" },
  },

  -- Custom highlight configs
  hl_neon = {
    category = "highlight",
    label = "Neon",
    renderer = "border_theme",
    border = "rounded",
    custom_highlights = neon_highlights,
  },

  hl_ember = {
    category = "highlight",
    label = "Ember",
    renderer = "border_theme",
    border = "rounded",
    custom_highlights = ember_highlights,
  },

  hl_ocean = {
    category = "highlight",
    label = "Ocean",
    renderer = "border_theme",
    border = "rounded",
    custom_highlights = ocean_highlights,
  },
}

-- Default VHS command for configs that don't specify one
M.default_cmd = ":set fold"

-- Ordered name lists (single source of truth for README generation + generate.sh)
M.renderer_names = { "popupmenu", "popupmenu_border", "popupmenu_palette", "wildmenu" }
M.feature_names = { "devicons", "fuzzy", "gradient", "search", "renderer_mux", "kind_icons" }
M.pipeline_names = { "lua_pipeline", "help_pipeline", "history_pipeline" }
M.highlight_names = { "hl_neon", "hl_ember", "hl_ocean" }
M.layout_names = {
  "laststatus_0", "laststatus_2", "laststatus_3",
  "cmdheight_0", "cmdheight_0_offset_1", "cmdheight_0_offset_2",
  "offset_1", "offset_2",
}
M.option_names = { "noselect_false", "reverse", "empty_message", "buffer_flags" }

-- Theme configs (generated)
M.theme_names = {
  "auto", "default", "saloon", "outlaw", "sunset", "prairie", "dusty",
  "midnight", "wanted", "cactus", "tumbleweed",
  "kanagawa", "kanagawa_dragon", "kanagawa_lotus",
  "catppuccin_mocha", "catppuccin_frappe", "catppuccin_latte",
  "tokyonight_night", "tokyonight_storm", "tokyonight_moon",
  "rose_pine", "rose_pine_moon", "rose_pine_dawn",
  "gruvbox_dark", "gruvbox_light", "nord", "onedark", "nightfox",
  "everforest_dark", "everforest_light", "dracula", "solarized_dark",
}

-- Theme metadata (descriptions for README generation)
M.theme_meta = {
  auto            = { renderer = "bordered", desc = "Derives colors from your colorscheme - a chameleon" },
  default         = { renderer = "plain",    desc = "Standard Pmenu links, no frills" },
  saloon          = { renderer = "bordered", desc = "Amber and whiskey - belly up to the bar" },
  outlaw          = { renderer = "bordered", desc = "Dark with crimson - wanted dead or alive" },
  sunset          = { renderer = "bordered", desc = "Orange to purple - end of the trail" },
  prairie         = { renderer = "bordered", desc = "Soft greens and earth - wide open spaces" },
  dusty           = { renderer = "bordered", desc = "Sandstone and sage - desert wanderer" },
  midnight        = { renderer = "bordered", desc = "Deep blue and silver - stars over the range" },
  wanted          = { renderer = "palette",  desc = "Parchment and ink - nailed to the post office wall" },
  cactus          = { renderer = "bordered", desc = "Green on dark soil - prickly but pretty" },
  tumbleweed      = { renderer = "plain",    desc = "Light and minimal - blowin' through town" },
  kanagawa        = { renderer = "bordered", desc = "Deep ink, warm autumn - the far east frontier" },
  kanagawa_dragon = { renderer = "bordered", desc = "Dark earth tones - dragon in the canyon" },
  kanagawa_lotus  = { renderer = "bordered", desc = "Light parchment - lotus in the desert spring" },
  catppuccin_mocha  = { renderer = "bordered", desc = "Rich dark pastels - lavender in the moonlight" },
  catppuccin_frappe = { renderer = "bordered", desc = "Dusky blue-grey pastels - twilight in the valley" },
  catppuccin_latte  = { renderer = "bordered", desc = "Warm light pastels - cream and ink at dawn" },
  tokyonight_night  = { renderer = "bordered", desc = "Deep midnight blue - neon in the dark" },
  tokyonight_storm  = { renderer = "bordered", desc = "Stormy dark blue - lightning on the horizon" },
  tokyonight_moon   = { renderer = "bordered", desc = "Soft moonlit blue - silver glow on the plains" },
  rose_pine         = { renderer = "bordered", desc = "Muted dark tones - wild roses at dusk" },
  rose_pine_moon    = { renderer = "bordered", desc = "Deeper purple base - roses under moonlight" },
  rose_pine_dawn    = { renderer = "bordered", desc = "Warm parchment light - roses at first light" },
  gruvbox_dark      = { renderer = "bordered", desc = "Warm retro earth - campfire in the canyon" },
  gruvbox_light     = { renderer = "bordered", desc = "Sandy retro light - parchment in the sun" },
  nord              = { renderer = "bordered", desc = "Arctic cool - frost on the frontier" },
  onedark           = { renderer = "bordered", desc = "Atom-inspired grey - steel and blue" },
  nightfox          = { renderer = "bordered", desc = "Deep ocean blue - foxfire in the night" },
  everforest_dark   = { renderer = "bordered", desc = "Woodland greens on dark soil - deep in the forest" },
  everforest_light  = { renderer = "bordered", desc = "Soft cream with fresh greens - forest clearing" },
  dracula           = { renderer = "bordered", desc = "Classic dark purple - the count rides at midnight" },
  solarized_dark    = { renderer = "bordered", desc = "Precision teal and cyan - the original classic" },
}

for _, name in ipairs(M.theme_names) do
  M.configs["theme_" .. name] = { category = "theme", theme = name }
end

-- Non-auto themes for random selection in non-theme screenshots
M._random_themes = {}
for _, name in ipairs(M.theme_names) do
  if name ~= "auto" then
    table.insert(M._random_themes, name)
  end
end

-- ── Random scene generation ──────────────────────────────────────

local function pick(t)
  return t[math.random(#t)]
end

function M.random_scene(label)
  local pipelines = {
    { "cmdline_fuzzy", "search" },
    { "lua", "cmdline_fuzzy", "search" },
    { "help_fuzzy", "cmdline_fuzzy", "search" },
  }
  local lefts = {
    { " " },
    { " ", "devicons" },
    { " ", "kind_icon" },
    { " ", "devicons", "kind_icon" },
  }
  local rights = {
    { " ", "scrollbar" },
    { " " },
  }
  local highlighters = { "fzy", "basic" }
  local custom_hl_sets = { neon_highlights, ember_highlights, ocean_highlights }

  -- Weighted recipe selection
  local recipe_weights = {
    { "theme", 40 },
    { "wildmenu", 15 },
    { "palette", 15 },
    { "border_custom", 10 },
    { "mux", 10 },
    { "gradient", 10 },
  }
  local total = 0
  for _, rw in ipairs(recipe_weights) do
    total = total + rw[2]
  end
  local roll = math.random(total)
  local recipe
  local acc = 0
  for _, rw in ipairs(recipe_weights) do
    acc = acc + rw[2]
    if roll <= acc then
      recipe = rw[1]
      break
    end
  end

  local scene = { label = label, pipeline = pick(pipelines) }

  if recipe == "theme" then
    scene.renderer = "theme:" .. pick(M._random_themes)
    scene.left = pick(lefts)
    scene.right = pick(rights)
    scene.highlighter = pick(highlighters)

  elseif recipe == "wildmenu" then
    scene.renderer = "wildmenu"
    scene.highlighter = "basic"
    scene.separator = " | "
    scene.left = { "arrows" }
    scene.right = { "arrows_right", " ", "index" }

  elseif recipe == "palette" then
    scene.renderer = "palette"
    scene.palette = {
      title = " Wildest ",
      prompt_prefix = " : ",
      prompt_position = "top",
      max_height = "60%",
      max_width = "60%",
      min_width = 40,
      margin = "auto",
    }
    scene.left = { " " }
    if math.random(2) == 1 then
      scene.custom_highlights = pick(custom_hl_sets)
    end

  elseif recipe == "border_custom" then
    scene.renderer = "border_theme"
    scene.border = "rounded"
    scene.custom_highlights = pick(custom_hl_sets)
    scene.left = pick(lefts)

  elseif recipe == "mux" then
    scene.renderer = "mux"
    scene.mux = {
      [":"] = {
        renderer = "theme:" .. pick(M._random_themes),
        highlighter = "fzy",
        highlights = { accent = "IncSearch", selected_accent = "IncSearch" },
        left = "devicons",
        right = { " ", "scrollbar" },
      },
      ["/"] = {
        renderer = "wildmenu",
        highlighter = "basic",
        highlights = { accent = "IncSearch", selected_accent = "IncSearch" },
        separator = " | ",
      },
    }

  elseif recipe == "gradient" then
    scene.renderer = "theme:" .. pick(M._random_themes)
    scene.highlights = false
    scene.highlighter = "gradient"
    scene.gradient_colors = rainbow_colors
    scene.left = { " " }
  end

  return scene
end

function M.random_scenes(n)
  local scenes = {}
  for i = 1, n do
    table.insert(scenes, M.random_scene("Scene " .. i))
  end
  return scenes
end

-- ── Resolver internals ───────────────────────────────────────────

local function resolve_pipeline(list, w)
  local branches = {}
  for _, name in ipairs(list) do
    if name == "cmdline_fuzzy" then
      table.insert(branches, w.cmdline_pipeline({ fuzzy = true }))
    elseif name == "search" then
      table.insert(branches, w.search_pipeline())
    elseif name == "lua" then
      table.insert(branches, w.lua_pipeline())
    elseif name == "help_fuzzy" then
      table.insert(branches, w.help_pipeline({ fuzzy = true }))
    elseif name == "history" then
      table.insert(branches, w.history_pipeline())
    end
  end
  return w.branch(unpack(branches))
end

local function resolve_component(name, w)
  if name == "devicons" then
    if M._has_devicons then
      return w.popupmenu_devicons()
    end
    return nil
  elseif name == "scrollbar" then
    return w.popupmenu_scrollbar()
  elseif name == "arrows" then
    return w.wildmenu_arrows()
  elseif name == "arrows_right" then
    return w.wildmenu_arrows({ right = true })
  elseif name == "index" then
    return w.wildmenu_index()
  elseif name == "kind_icon" then
    return w.popupmenu_kind_icon()
  elseif name == "buffer_flags" then
    return w.popupmenu_buffer_flags()
  else
    return name
  end
end

local function resolve_components(list, w)
  if not list then
    return nil
  end
  if type(list) == "string" then
    if list == "devicons" then
      if M._has_devicons then
        return { " ", w.popupmenu_devicons() }
      end
      return { " " }
    end
  end
  local result = {}
  for _, item in ipairs(list) do
    local resolved = resolve_component(item, w)
    if resolved ~= nil then
      table.insert(result, resolved)
    end
  end
  return result
end

local function resolve_highlighter(cfg, w)
  local name = cfg.highlighter or "fzy"
  if name == "basic" then
    return w.basic_highlighter()
  elseif name == "gradient" then
    local gradient = {}
    for i, color in ipairs(cfg.gradient_colors) do
      local hl_name = "WildestGradient" .. i
      vim.api.nvim_set_hl(0, hl_name, { fg = color, bold = true })
      table.insert(gradient, hl_name)
    end
    return w.gradient_highlighter(w.fzy_highlighter(), gradient)
  else
    return w.fzy_highlighter()
  end
end

local function build_renderer_opts(cfg, w)
  local opts = {}
  opts.highlighter = resolve_highlighter(cfg, w)
  if cfg.highlights and cfg.highlights ~= false then
    opts.highlights = cfg.highlights
  end
  local left = resolve_components(cfg.left, w)
  if left then
    opts.left = left
  end
  local right = resolve_components(cfg.right, w)
  if right then
    opts.right = right
  end
  if cfg.separator then
    opts.separator = cfg.separator
  end
  if cfg.border then
    opts.border = cfg.border
  end
  if cfg.offset then
    opts.offset = cfg.offset
  end
  if cfg.reverse then
    opts.reverse = cfg.reverse
  end
  if cfg.empty_message then
    opts.empty_message = cfg.empty_message
  end
  return opts
end

local function build_single_renderer(cfg, w)
  local renderer_key = cfg.renderer or "theme:auto"
  local opts = build_renderer_opts(cfg, w)

  if renderer_key == "popupmenu" then
    return w.popupmenu_renderer(opts)
  elseif renderer_key == "wildmenu" then
    return w.wildmenu_renderer(opts)
  elseif renderer_key == "border_theme" then
    return w.popupmenu_border_theme(opts)
  elseif renderer_key == "palette" then
    return w.extend_theme("auto", {
      renderer = "palette",
      renderer_opts = cfg.palette,
    }).renderer(opts)
  elseif renderer_key:match("^theme:") then
    local theme_name = renderer_key:match("^theme:(.+)$")
    return w.theme(theme_name).renderer(opts)
  end
end

-- ── Public build ─────────────────────────────────────────────────

function M.build(name_or_cfg, w)
  local cfg
  if type(name_or_cfg) == "string" then
    cfg = M.configs[name_or_cfg]
    if not cfg then
      vim.notify("[screenshots] Unknown config: " .. name_or_cfg, vim.log.levels.ERROR)
      vim.notify(
        "[screenshots] Available: " .. table.concat(vim.tbl_keys(M.configs), ", "),
        vim.log.levels.INFO
      )
      cfg = M.configs.popupmenu_border
    end
  else
    cfg = name_or_cfg
  end

  local merged = vim.tbl_extend("keep", cfg, M.defaults)

  -- Theme shorthand: use theme renderer, skip accent highlights
  if merged.theme then
    merged.renderer = "theme:" .. merged.theme
    merged.highlights = false
  end

  -- Randomize theme for GIF scenes (no category) that inherit theme:auto
  if not merged.category and merged.renderer == "theme:auto" then
    local pick = M._random_themes[math.random(#M._random_themes)]
    merged.renderer = "theme:" .. pick
  end

  -- Custom highlights: apply them, skip accent highlights
  if merged.custom_highlights then
    for hl_name, hl in pairs(merged.custom_highlights) do
      vim.api.nvim_set_hl(0, hl_name, hl)
    end
    merged.highlights = false
  end

  -- Pipeline
  local pipeline = resolve_pipeline(merged.pipeline, w)

  -- Renderer
  local renderer
  if merged.renderer == "mux" then
    local mux_map = {}
    for mode, entry in pairs(merged.mux) do
      mux_map[mode] = build_single_renderer(entry, w)
    end
    renderer = w.renderer_mux(mux_map)
  else
    renderer = build_single_renderer(merged, w)
  end

  -- Collect setup-level option overrides.
  local setup_opts = { pipeline = pipeline, renderer = renderer }
  if merged.noselect ~= nil then
    setup_opts.noselect = merged.noselect
  end

  -- Collect vim option overrides to return to the caller.
  -- The caller should apply these AFTER w.setup() so that nothing
  -- (theme.apply, setup_default_highlights, etc.) can reset them.
  local vim_opts = {}
  if merged.laststatus ~= nil then
    vim_opts.laststatus = merged.laststatus
  end
  if merged.cmdheight ~= nil then
    vim_opts.cmdheight = merged.cmdheight
  end

  return setup_opts, vim_opts
end

--- Apply vim option overrides returned by M.build().
---@param vim_opts table { laststatus?, cmdheight? }
function M.apply_vim_opts(vim_opts)
  if vim_opts.laststatus ~= nil then
    vim.o.laststatus = vim_opts.laststatus
  end
  if vim_opts.cmdheight ~= nil then
    vim.o.cmdheight = vim_opts.cmdheight
  end
end

return M
