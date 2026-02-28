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
  right = { "scrollbar" },
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
      prompt_prefix = " :",
      prompt_position = "top",
      max_height = "60%",
      max_width = "60%",
      min_width = 40,
      margin = "auto",
    },
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

  palette_prompt_bottom = {
    category = "renderer",
    label = "Palette (Bottom Prompt)",
    renderer = "palette",
    palette = {
      title = " Wildest ",
      prompt_position = "bottom",
      max_height = "60%",
      max_width = "60%",
      min_width = 40,
      margin = "auto",
    },
  },

  -- Feature configs
  devicons = {
    category = "feature",
    cmd = ":e init",
    left = { "devicons" },
  },

  fuzzy = {
    category = "feature",
    cmd = ":e rend",
  },

  gradient = {
    category = "feature",
    cmd = ":help help-",
    highlights = false,
    highlighter = "gradient",
    gradient_colors = rainbow_colors,
  },

  search = {
    category = "feature",
    cmd = "/function",
    highlighter = "basic",
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
        right = { "scrollbar" },
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
    left = { "kind_icon" },
  },

  prefix_highlighter = {
    category = "feature",
    label = "Prefix Highlighter",
    cmd = ":e conf",
    highlighter = "prefix",
  },

  scrollbar = {
    category = "feature",
    label = "Scrollbar",
    cmd = ":help nvim",
    right = { "scrollbar" },
  },

  pumblend = {
    category = "feature",
    label = "Pumblend",
    renderer = "border_theme",
    border = "rounded",
    pumblend = 30,
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

  empty_message_popupmenu = {
    category = "option",
    label = "empty_message (popupmenu)",
    cmd = ":zzzznotacommand",
    renderer = "popupmenu",
    highlighter = "basic",
    empty_message = " No matches, partner ",
  },

  buffer_flags = {
    category = "option",
    cmd = ":b ",
    pipeline = { "cmdline_fuzzy" },
    left = { "buffer_flags" },
  },

  position_top = {
    category = "option",
    label = "position=top",
    renderer = "border_theme",
    border = "rounded",
    position = "top",
  },

  position_center = {
    category = "option",
    label = "position=center",
    renderer = "border_theme",
    border = "rounded",
    position = "center",
  },

  ellipsis = {
    category = "option",
    label = "ellipsis",
    renderer = "wildmenu",
    highlighter = "basic",
    separator = " | ",
    ellipsis = "...",
    left = { "arrows" },
    right = { "arrows_right", " ", "index" },
  },

  position_top_bordered = {
    category = "option",
    label = "position=top (bordered)",
    renderer = "border_theme",
    border = "rounded",
    position = "top",
    title = " Completions ",
  },

  noselect_bordered = {
    category = "option",
    label = "noselect (bordered)",
    renderer = "border_theme",
    border = "rounded",
    noselect = true,
  },

  fixed_height_true = {
    category = "option",
    label = "fixed_height=true",
    cmd = ":set wra",
    renderer = "border_theme",
    border = "rounded",
    fixed_height = true,
  },

  -- Border style configs
  border_rounded = {
    category = "border",
    label = "Rounded",
    renderer = "border_theme",
    border = "rounded",
  },

  border_single = {
    category = "border",
    label = "Single",
    renderer = "border_theme",
    border = "single",
  },

  border_double = {
    category = "border",
    label = "Double",
    renderer = "border_theme",
    border = "double",
  },

  border_solid = {
    category = "border",
    label = "Solid",
    renderer = "border_theme",
    border = "solid",
  },

  border_title = {
    category = "border",
    label = "With Title",
    renderer = "border_theme",
    border = "rounded",
    title = " Completions ",
  },

  -- Wildmenu variant configs
  wildmenu_dot = {
    category = "wildmenu_variant",
    label = "Dot Separator",
    renderer = "wildmenu",
    highlighter = "basic",
    separator = " · ",
    left = { "arrows" },
    right = { "arrows_right", " ", "index" },
  },

  wildmenu_reverse = {
    category = "wildmenu_variant",
    label = "Reversed",
    renderer = "wildmenu",
    highlighter = "fzy",
    separator = " | ",
    reverse = true,
    left = { "arrows" },
    right = { "arrows_right", " ", "index" },
  },

  wildmenu_minimal = {
    category = "wildmenu_variant",
    label = "Minimal",
    renderer = "wildmenu",
    highlighter = "basic",
    separator = "  ",
  },

  wildmenu_pipe = {
    category = "wildmenu_variant",
    label = "Pipe Separator",
    renderer = "wildmenu",
    highlighter = "fzy",
    separator = " │ ",
    left = { "arrows" },
    right = { "arrows_right" },
  },

  wildmenu_arrows_index = {
    category = "wildmenu_variant",
    label = "Arrows + Index",
    renderer = "wildmenu",
    highlighter = "basic",
    separator = " · ",
    left = { "arrows" },
    right = { "arrows_right", " ", "index" },
  },

  wildmenu_compact = {
    category = "wildmenu_variant",
    label = "Compact",
    renderer = "wildmenu",
    highlighter = "basic",
    separator = " ",
  },

  -- Palette variant configs
  palette_no_title = {
    category = "palette_variant",
    label = "No Title",
    renderer = "palette",
    palette = {
      prompt_position = "top",
      max_height = "60%",
      max_width = "60%",
      min_width = 40,
      margin = "auto",
    },
  },

  palette_custom_prefix = {
    category = "palette_variant",
    label = "Custom Prefix",
    cmd = "/function",
    renderer = "palette",
    palette = {
      title = " Search ",
      prompt_position = "top",
      max_height = "60%",
      max_width = "60%",
      min_width = 40,
      margin = "auto",
    },
  },

  palette_large = {
    category = "palette_variant",
    label = "Large",
    renderer = "palette",
    palette = {
      title = " Wildest ",
      prompt_position = "top",
      max_height = "75%",
      max_width = "75%",
      min_width = 50,
      margin = "auto",
    },
  },

  palette_compact = {
    category = "palette_variant",
    label = "Compact",
    renderer = "palette",
    palette = {
      title = " Wildest ",
      prompt_position = "top",
      max_height = "40%",
      max_width = "40%",
      min_width = 30,
      margin = "auto",
    },
  },

  palette_search = {
    category = "palette_variant",
    label = "Search Mode",
    cmd = "/function",
    renderer = "palette",
    palette = {
      title = " Search ",
      prompt_prefix = " / ",
      prompt_position = "top",
      max_height = "60%",
      max_width = "60%",
      min_width = 40,
      margin = "auto",
    },
  },

  -- Dimension configs
  max_height_small = {
    category = "dimension",
    label = "max_height=8",
    renderer = "border_theme",
    border = "rounded",
    max_height = 8,
  },

  fixed_height_false = {
    category = "dimension",
    label = "fixed_height=false",
    cmd = ":set wra",
    renderer = "border_theme",
    border = "rounded",
    fixed_height = false,
  },

  max_width_60 = {
    category = "dimension",
    label = "max_width=60",
    renderer = "border_theme",
    border = "rounded",
    max_width = 60,
  },

  min_height_5 = {
    category = "dimension",
    label = "min_height=5",
    cmd = ":set wra",
    renderer = "border_theme",
    border = "rounded",
    min_height = 5,
  },

  max_height_large = {
    category = "dimension",
    label = "max_height=20",
    renderer = "border_theme",
    border = "rounded",
    max_height = 20,
  },

  max_width_40 = {
    category = "dimension",
    label = "max_width=40",
    renderer = "border_theme",
    border = "rounded",
    max_width = 40,
  },

  min_width_40 = {
    category = "dimension",
    label = "min_width=40",
    cmd = ":set wra",
    renderer = "border_theme",
    border = "rounded",
    min_width = 40,
  },

  -- Gradient variant configs
  gradient_warm = {
    category = "gradient",
    label = "Warm",
    cmd = ":help nvim_b",
    highlights = false,
    highlighter = "gradient",
    gradient_colors = { "#ff2200", "#ff6600", "#ff9900", "#ffcc00", "#ffee00", "#ffff44" },
  },

  gradient_cool = {
    category = "gradient",
    label = "Cool",
    cmd = ":help api-",
    highlights = false,
    highlighter = "gradient",
    gradient_colors = { "#00ffff", "#00ccff", "#0099ff", "#0066ff", "#6600ff", "#cc00ff" },
  },

  gradient_sunset = {
    category = "gradient",
    label = "Sunset",
    cmd = ":help option-",
    highlights = false,
    highlighter = "gradient",
    gradient_colors = { "#8800cc", "#cc44aa", "#ff6644", "#ff8800", "#ffaa00", "#ffcc22" },
  },

  gradient_ice = {
    category = "gradient",
    label = "Ice",
    cmd = ":help vim.",
    highlights = false,
    highlighter = "gradient",
    gradient_colors = { "#ffffff", "#ccddff", "#88bbff", "#4488ff", "#2244cc", "#001188" },
  },

  gradient_forest = {
    category = "gradient",
    label = "Forest",
    cmd = ":help auto",
    highlights = false,
    highlighter = "gradient",
    gradient_colors = { "#004400", "#006600", "#228800", "#44bb00", "#88dd00", "#ccee22" },
  },

  -- Combination configs
  devicons_kind = {
    category = "combination",
    label = "Devicons + Kind",
    cmd = ":e init",
    left = { "devicons", "kind_icon" },
    right = { "scrollbar" },
  },

  reverse_bordered = {
    category = "combination",
    label = "Reverse + Border",
    renderer = "border_theme",
    border = "rounded",
    reverse = true,
  },

  accent_incsearch = {
    category = "combination",
    label = "IncSearch Accent",
    cmd = ":e high",
    highlights = { accent = "IncSearch", selected_accent = "IncSearch" },
  },

  noselect_reverse = {
    category = "combination",
    label = "Noselect + Reverse",
    renderer = "border_theme",
    border = "rounded",
    noselect = true,
    reverse = true,
  },

  pumblend_bordered = {
    category = "combination",
    label = "Pumblend + Border",
    renderer = "border_theme",
    border = "rounded",
    pumblend = 20,
  },

  devicons_scrollbar_border = {
    category = "combination",
    label = "Devicons + Scrollbar + Border",
    cmd = ":e init",
    renderer = "border_theme",
    border = "rounded",
    left = { "devicons" },
    right = { "scrollbar" },
  },

  gradient_bordered = {
    category = "combination",
    label = "Gradient + Border",
    cmd = ":help nvim_b",
    renderer = "border_theme",
    border = "rounded",
    highlights = false,
    highlighter = "gradient",
    gradient_colors = rainbow_colors,
  },

  palette_gradient = {
    category = "combination",
    label = "Palette + Gradient",
    cmd = ":help api-",
    renderer = "palette",
    highlights = false,
    highlighter = "gradient",
    gradient_colors = { "#ff2200", "#ff6600", "#ff9900", "#ffcc00", "#ffee00", "#ffff44" },
    palette = {
      title = " Wildest ",
      prompt_position = "top",
      max_height = "60%",
      max_width = "60%",
      min_width = 40,
      margin = "auto",
    },
  },

  wildmenu_fzy = {
    category = "combination",
    label = "Wildmenu + Fzy",
    renderer = "wildmenu",
    highlighter = "fzy",
    separator = " | ",
    left = { "arrows" },
    right = { "arrows_right", " ", "index" },
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
M.renderer_names = { "popupmenu", "popupmenu_border", "popupmenu_palette", "palette_prompt_bottom", "wildmenu" }
M.feature_names = {
  "devicons", "fuzzy", "gradient", "search", "renderer_mux", "kind_icons",
  "prefix_highlighter", "scrollbar", "pumblend",
}
M.pipeline_names = { "lua_pipeline", "help_pipeline", "history_pipeline" }
M.highlight_names = { "hl_neon", "hl_ember", "hl_ocean" }
M.border_names = { "border_rounded", "border_single", "border_double", "border_solid", "border_title" }
M.wildmenu_variant_names = { "wildmenu_dot", "wildmenu_reverse", "wildmenu_minimal", "wildmenu_pipe", "wildmenu_arrows_index", "wildmenu_compact" }
M.palette_variant_names = { "palette_no_title", "palette_custom_prefix", "palette_large", "palette_compact", "palette_search" }
M.dimension_names = { "max_height_small", "fixed_height_false", "max_width_60", "min_height_5", "max_height_large", "max_width_40", "min_width_40" }
M.gradient_names = { "gradient_warm", "gradient_cool", "gradient_sunset", "gradient_ice", "gradient_forest" }
M.combination_names = { "devicons_kind", "reverse_bordered", "accent_incsearch", "noselect_reverse", "pumblend_bordered", "devicons_scrollbar_border", "gradient_bordered", "palette_gradient", "wildmenu_fzy" }
M.layout_names = {
  "laststatus_0", "laststatus_2", "laststatus_3",
  "cmdheight_0", "cmdheight_0_offset_1", "cmdheight_0_offset_2",
  "offset_1", "offset_2",
}
M.option_names = {
  "noselect_false", "reverse", "empty_message", "empty_message_popupmenu",
  "buffer_flags", "position_top", "position_center", "ellipsis",
  "position_top_bordered", "noselect_bordered", "fixed_height_true",
}

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

local scene_names = {
  "Tumbleweeds Roll", "Prairie Dust", "Clock Tower", "The Draw",
  "Quickfire", "Ricochet", "Smoke Clears", "Sunset Silhouette",
  "Dust Settles", "The Legend", "The Stranger Rides In", "Quick Draw",
  "High Noon", "Tumbleweed", "Neon Saloon", "Sunset Riders",
  "The Posse", "Ember Trail", "Ride Into the Sunset", "Wanted",
  "Rustler's Moon", "Coyote Howl", "Dusty Trail", "Gallows Humor",
  "Last Stand", "Campfire Glow", "Gold Rush", "Canyon Echo",
  "Barbed Wire", "Whiskey Creek",
}

local function pick(t)
  return t[math.random(#t)]
end

function M.random_scene(label)
  local pipelines = {
    { "cmdline_fuzzy", "search" },
    { "lua", "cmdline_fuzzy", "search" },
    { "help_fuzzy", "cmdline_fuzzy", "search" },
    { "history", "cmdline_fuzzy", "search" },
  }
  local lefts = {
    {},
    { "devicons" },
    { "kind_icon" },
    { "devicons", "kind_icon" },
    { "buffer_flags" },
  }
  local rights = {
    { "scrollbar" },
    {},
  }
  local highlighters = { "fzy", "basic", "prefix" }
  local borders = { "rounded", "single", "double", "solid" }
  local custom_hl_sets = { neon_highlights, ember_highlights, ocean_highlights }

  local gradient_palettes = {
    rainbow_colors,
    { "#ff6600", "#ff9900", "#ffcc00", "#ffff00", "#ccff00", "#66ff00" },
    { "#00ffff", "#00ccff", "#0099ff", "#0066ff", "#6600ff", "#cc00ff" },
  }

  -- Weighted recipe selection
  local recipe_weights = {
    { "theme", 35 },
    { "wildmenu", 15 },
    { "palette", 15 },
    { "border_custom", 12 },
    { "mux", 13 },
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

  -- Sprinkle renderer options randomly across all recipes
  if math.random(6) == 1 then
    scene.noselect = true
  end
  if math.random(8) == 1 then
    scene.reverse = true
  end
  if math.random(5) == 1 then
    scene.pumblend = pick({ 10, 20, 30 })
  end
  if math.random(6) == 1 then
    scene.offset = pick({ 1, 2 })
  end
  if math.random(8) == 1 then
    scene.empty_message = pick({ " No matches ", " Nothing found ", " ∅ " })
  end
  if math.random(4) == 1 then
    scene.max_height = pick({ 8, 10, 12, 20 })
  end
  if math.random(5) == 1 then
    scene.min_height = pick({ 3, 5, 8 })
  end
  if math.random(4) == 1 then
    scene.fixed_height = pick({ true, false })
  end

  if recipe == "theme" then
    scene.renderer = "theme:" .. pick(M._random_themes)
    scene.left = pick(lefts)
    scene.right = pick(rights)
    scene.highlighter = pick(highlighters)

  elseif recipe == "wildmenu" then
    scene.renderer = "wildmenu"
    scene.highlighter = pick(highlighters)
    scene.separator = pick({ " | ", "  ", " · " })
    scene.ellipsis = pick({ "...", "…", " >" })
    scene.left = pick({ { "arrows" }, {} })
    scene.right = pick({ { "arrows_right", " ", "index" }, { "index" }, {} })

  elseif recipe == "palette" then
    scene.renderer = "palette"
    scene.palette = {
      title = pick({ " Wildest ", " Command ", nil }),
      prompt_position = pick({ "top", "bottom" }),
      max_height = pick({ "60%", "75%", "50%" }),
      max_width = pick({ "60%", "75%", "50%" }),
      min_width = pick({ 30, 40, 50 }),
      margin = "auto",
    }
    scene.highlighter = pick(highlighters)
    scene.left = pick(lefts)
    if math.random(2) == 1 then
      scene.custom_highlights = pick(custom_hl_sets)
    end

  elseif recipe == "border_custom" then
    scene.renderer = "border_theme"
    scene.border = pick(borders)
    scene.position = pick({ "bottom", "bottom", "top", "center" })
    scene.highlighter = pick(highlighters)
    scene.custom_highlights = pick(custom_hl_sets)
    scene.left = pick(lefts)
    scene.right = pick(rights)

  elseif recipe == "mux" then
    scene.renderer = "mux"
    scene.mux = {
      [":"] = {
        renderer = "theme:" .. pick(M._random_themes),
        highlighter = pick(highlighters),
        highlights = { accent = "IncSearch", selected_accent = "IncSearch" },
        left = pick({ "devicons", {}, { "kind_icon" } }),
        right = pick(rights),
      },
      ["/"] = {
        renderer = pick({ "wildmenu", "theme:" .. pick(M._random_themes) }),
        highlighter = pick(highlighters),
        highlights = { accent = "IncSearch", selected_accent = "IncSearch" },
        separator = " | ",
      },
    }

  elseif recipe == "gradient" then
    scene.renderer = "theme:" .. pick(M._random_themes)
    scene.highlights = false
    scene.highlighter = "gradient"
    scene.gradient_colors = pick(gradient_palettes)
    scene.left = pick(lefts)
    scene.right = pick(rights)
  end

  return scene
end

function M.random_scenes(n)
  -- Shuffle scene names so each run gets a unique order
  local names = {}
  for _, name in ipairs(scene_names) do
    table.insert(names, name)
  end
  for i = #names, 2, -1 do
    local j = math.random(i)
    names[i], names[j] = names[j], names[i]
  end

  local scenes = {}
  for i = 1, n do
    local label = names[((i - 1) % #names) + 1]
    table.insert(scenes, M.random_scene(label))
  end
  return scenes
end

-- ── Scene description ────────────────────────────────────────────

local function fmt_val(v)
  if type(v) == "string" then
    return '"' .. v .. '"'
  elseif type(v) == "boolean" then
    return tostring(v)
  elseif type(v) == "number" then
    return tostring(v)
  elseif type(v) == "table" then
    -- Shallow: list of strings/numbers
    local parts = {}
    local is_list = #v > 0
    if is_list then
      for _, item in ipairs(v) do
        table.insert(parts, fmt_val(item))
      end
      return "{ " .. table.concat(parts, ", ") .. " }"
    else
      for k, sv in pairs(v) do
        table.insert(parts, k .. " = " .. fmt_val(sv))
      end
      return "{ " .. table.concat(parts, ", ") .. " }"
    end
  end
  return tostring(v)
end

--- Emit the `require('wildest').setup({...})` body for a config table.
---@param cfg table  scene or resolved config
---@param lines string[]
---@param add fun(s: string)
local function setup_block_lines(cfg, lines, add)
  add("require('wildest').setup({")

  -- Core fields
  local field_order = {
    "renderer", "pipeline", "highlighter",
    "padding", "left", "right", "separator", "ellipsis",
    "border", "title", "position",
    "max_height", "min_height", "max_width", "min_width", "fixed_height",
    "noselect", "reverse", "pumblend", "offset",
    "empty_message",
    "highlights", "gradient_colors",
  }

  for _, key in ipairs(field_order) do
    local val = cfg[key]
    if val ~= nil then
      add("  " .. key .. " = " .. fmt_val(val) .. ",")
    end
  end

  -- Palette sub-table
  if cfg.palette then
    add("  palette = {")
    for k, v in pairs(cfg.palette) do
      add("    " .. k .. " = " .. fmt_val(v) .. ",")
    end
    add("  },")
  end

  -- Custom highlights (just show the names)
  if cfg.custom_highlights then
    local hl_names = {}
    for name, _ in pairs(cfg.custom_highlights) do
      table.insert(hl_names, name)
    end
    table.sort(hl_names)
    add("  custom_highlights = {")
    for _, name in ipairs(hl_names) do
      add("    " .. name .. " = { ... },")
    end
    add("  },")
  end

  -- Mux sub-table
  if cfg.mux then
    add("  mux = {")
    for mode, entry in pairs(cfg.mux) do
      add('    ["' .. mode .. '"] = {')
      for k, v in pairs(entry) do
        add("      " .. k .. " = " .. fmt_val(v) .. ",")
      end
      add("    },")
    end
    add("  },")
  end

  add("})")
end

--- Format a scene table as readable config lines for buffer display.
---@param scene table
---@param index number|nil scene index
---@param total number|nil total scenes
---@return string[] lines
function M.scene_to_lines(scene, index, total)
  local lines = {}
  local function add(s) table.insert(lines, s) end

  add("-- wildest.nvim")
  if index and total then
    add("-- Scene " .. index .. "/" .. total .. ': "' .. (scene.label or "") .. '"')
  else
    add('-- "' .. (scene.label or "") .. '"')
  end
  add("-- " .. string.rep("─", 50))
  add("")

  setup_block_lines(scene, lines, add)

  return lines
end

--- Format a named config as readable lines for screenshot buffer display.
---@param name string  config key from M.configs
---@return string[] lines
function M.config_to_lines(name)
  local cfg = M.configs[name]
  if not cfg then
    return { "-- unknown config: " .. name }
  end

  local label = cfg.label or name
  local lines = {}
  local function add(s) table.insert(lines, s) end

  add("-- wildest.nvim")
  add('-- "' .. label .. '" (' .. name .. ")")
  add("-- " .. string.rep("─", 50))
  add("")

  setup_block_lines(cfg, lines, add)

  return lines
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
        return { w.popupmenu_devicons() }
      end
      return {}
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
  elseif name == "prefix" then
    return w.prefix_highlighter()
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
  if cfg.padding then
    opts.padding = cfg.padding
  end
  if cfg.separator then
    opts.separator = cfg.separator
  end
  if cfg.border then
    opts.border = cfg.border
  end
  if cfg.title then
    opts.title = cfg.title
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
  if cfg.pumblend then
    opts.pumblend = cfg.pumblend
  end
  if cfg.position then
    opts.position = cfg.position
  end
  if cfg.ellipsis then
    opts.ellipsis = cfg.ellipsis
  end
  if cfg.max_height then
    opts.max_height = cfg.max_height
  end
  if cfg.min_height then
    opts.min_height = cfg.min_height
  end
  if cfg.max_width then
    opts.max_width = cfg.max_width
  end
  if cfg.min_width then
    opts.min_width = cfg.min_width
  end
  if cfg.fixed_height ~= nil then
    opts.fixed_height = cfg.fixed_height
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

-- ── Shared setup defaults ────────────────────────────────────────

M.setup_defaults = {
  modes = { ":", "/", "?" },
  next_key = "<Tab>",
  previous_key = "<S-Tab>",
  accept_key = "<Down>",
  reject_key = "<Up>",
}

-- ── Screenshot init helper ──────────────────────────────────────

--- Bootstrap a screenshot session: set buffer content to the config's own
--- description, apply the config, and configure wildest.
---@param config_name string  key from M.configs (or env WILDEST_CONFIG)
function M.screenshot_init(config_name)
  local configs_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h")
  local root = vim.fn.fnamemodify(configs_dir, ":h:h")
  M.setup(root)

  local w = require("wildest")
  config_name = config_name or "popupmenu_border"
  vim.o.statusline = " %f %m%= " .. config_name .. " "

  -- Write config description as buffer content
  local lines = M.config_to_lines(config_name)
  vim.bo.modifiable = true
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.bo.filetype = "lua"
  vim.bo.modified = false
  vim.api.nvim_win_set_cursor(0, { 1, 0 })

  local built, vim_opts = M.build(config_name, w)
  w.setup(vim.tbl_extend("force", M.setup_defaults, built))
  M.apply_vim_opts(vim_opts)
end

-- ── GIF init helper ──────────────────────────────────────────────

--- Bootstrap a GIF session: generate scenes, dump JSON, wire <C-n> cycling.
---@param name string  GIF name used for the JSON dump (e.g. "showdown")
---@param n number|nil Number of scenes (default 25)
function M.gif_init(name, n)
  local configs_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h")
  local root = vim.fn.fnamemodify(configs_dir, ":h:h")
  M.setup(root)

  local w = require("wildest")
  n = n or 25
  local scenes = M.random_scenes(n)

  -- Dump scene configs for debugging
  local out_dir = configs_dir .. "/output"
  vim.fn.mkdir(out_dir, "p")
  local f = io.open(out_dir .. "/" .. name .. "_scenes.json", "w")
  if f then
    f:write(vim.json.encode(scenes))
    f:close()
  end

  local current_scene = 1

  local function apply_scene(index)
    local scene = scenes[index]
    if not scene then
      return
    end
    vim.o.statusline = " %f %= " .. index .. "/" .. #scenes .. "  " .. scene.label .. " "

    -- Write scene config as buffer content
    local lines = M.scene_to_lines(scene, index, #scenes)
    vim.bo.modifiable = true
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.bo.filetype = "lua"
    vim.bo.modified = false
    vim.api.nvim_win_set_cursor(0, { 1, 0 })

    local built, vim_opts = M.build(scene, w)
    w.setup(vim.tbl_extend("force", M.setup_defaults, built))
    M.apply_vim_opts(vim_opts)
  end

  vim.keymap.set("n", "<C-n>", function()
    current_scene = current_scene + 1
    if current_scene > #scenes then
      current_scene = 1
    end
    apply_scene(current_scene)
  end, { noremap = true, silent = true })

  apply_scene(1)
end

return M
