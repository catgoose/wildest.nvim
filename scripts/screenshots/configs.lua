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

  local ok = pcall(vim.cmd.colorscheme, "kanagawa")
  if not ok then
    vim.cmd.colorscheme("habamax")
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
    cmd = ":e lua/wildest/renderer/components/",
    left = { "devicons" },
  },

  fuzzy = {
    category = "feature",
    cmd = ":e tests/test_c",
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

  fuzzy_search = {
    category = "feature",
    cmd = "/fnctn",
    highlighter = "fzy",
    pipeline = { "cmdline_fuzzy", "search_fuzzy" },
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

  cmdline_icon = {
    category = "feature",
    label = "Cmdline Icon",
    cmd = ":e lua/wildest/renderer/components/",
    left = { "cmdline_icon" },
  },

  cmdline_icon_help = {
    category = "feature",
    label = "Cmdline Icon (Help)",
    cmd = ":help nvim_b",
    pipeline = { "help_fuzzy", "cmdline_fuzzy" },
    left = { "cmdline_icon" },
  },

  prefix_highlighter = {
    category = "feature",
    label = "Prefix Highlighter",
    cmd = ":e tests/",
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

  chain_highlighter = {
    category = "feature",
    label = "Chain Highlighter",
    highlighter = "chain",
  },

  scrollbar_collapse = {
    category = "feature",
    label = "Scrollbar (collapse)",
    cmd = ":set wra",
    right = { "scrollbar_collapse" },
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

  shell_pipeline = {
    category = "pipeline",
    label = "Shell Commands",
    cmd = ":!gi",
    pipeline = { "shell_fuzzy", "cmdline_fuzzy" },
  },

  substitute_pipeline = {
    category = "pipeline",
    label = "Substitute",
    cmd = ":%s/func",
    pipeline = { "substitute", "cmdline_fuzzy" },
  },

  history_prefix_pipeline = {
    category = "pipeline",
    label = "History (Prefix)",
    pipeline = { "history_prefix", "cmdline_fuzzy" },
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

  top_component = {
    category = "option",
    label = "top component",
    renderer = "border_theme",
    border = "rounded",
    top = { " Matches:" },
  },

  bottom_component = {
    category = "option",
    label = "bottom component",
    renderer = "border_theme",
    border = "rounded",
    bottom = { " Press <Tab> to navigate " },
  },

  top_bottom_components = {
    category = "option",
    label = "top + bottom",
    renderer = "border_theme",
    border = "rounded",
    top = { " Completions" },
    bottom = { " <Tab>/<S-Tab> to navigate " },
  },

  before_cursor = {
    category = "option",
    label = "before_cursor",
    cmd = ":edit lua/wildest/init remaining_text",
    pipeline = { "cmdline_fuzzy_before_cursor" },
  },

  sort_buffers_lastused = {
    category = "option",
    label = "sort_buffers_lastused",
    cmd = ":b ",
    pipeline = { "cmdline_buffers_lastused" },
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

  wildmenu_powerline = {
    category = "wildmenu_variant",
    label = "Powerline",
    renderer = "wildmenu",
    highlighter = "basic",
    separator = "powerline",
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
    cmd = ":e lua/wildest/renderer/components/",
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
    cmd = ":e lua/wildest/renderer/components/",
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
    cmd = ":e lua/wildest/renderer/components/",
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

  -- Preview configs
  preview_right_screen = {
    category = "preview",
    label = "Preview Right (Screen)",
    cmd = ":e lua/wildest/renderer/components/",
    noselect = false,
    preview = { position = "right", anchor = "screen", width = "40%", border = "rounded" },
  },

  preview_left_screen = {
    category = "preview",
    label = "Preview Left (Screen)",
    cmd = ":e lua/wildest/renderer/components/",
    noselect = false,
    preview = { position = "left", anchor = "screen", width = "40%", border = "rounded" },
  },

  preview_top_screen = {
    category = "preview",
    label = "Preview Top (Screen)",
    cmd = ":e lua/wildest/renderer/components/",
    noselect = false,
    preview = { position = "top", anchor = "screen", height = "40%", border = "rounded" },
  },

  preview_bottom_screen = {
    category = "preview",
    label = "Preview Bottom (Screen)",
    cmd = ":e lua/wildest/renderer/components/",
    noselect = false,
    preview = { position = "bottom", anchor = "screen", height = "40%", border = "rounded" },
  },

  preview_right_popup = {
    category = "preview",
    label = "Preview Right (Popup)",
    cmd = ":e lua/wildest/renderer/components/",
    noselect = false,
    preview = { position = "right", anchor = "popup", width = "40%", border = "rounded" },
  },

  preview_left_popup = {
    category = "preview",
    label = "Preview Left (Popup)",
    cmd = ":e lua/wildest/renderer/components/",
    noselect = false,
    preview = { position = "left", anchor = "popup", width = "40%", border = "rounded" },
  },

  preview_top_popup = {
    category = "preview",
    label = "Preview Top (Popup)",
    cmd = ":e lua/wildest/renderer/components/",
    noselect = false,
    preview = { position = "top", anchor = "popup", height = "40%", border = "rounded" },
  },

  preview_bottom_popup = {
    category = "preview",
    label = "Preview Bottom (Popup)",
    cmd = ":e lua/wildest/renderer/components/",
    noselect = false,
    preview = { position = "bottom", anchor = "popup", height = "40%", border = "rounded" },
  },

  -- Wanted-poster preview configs: palette renderer + popup anchor + wide preview
  -- that exercises dynamic clamping (preview shrinks to fit remaining space).
  preview_wanted_right = {
    category = "preview",
    label = "Wanted Right",
    theme = "wanted",
    cmd = ":e lua/wildest/renderer/components/",
    noselect = false,
    preview = { position = "right", anchor = "popup", width = "60%", border = "rounded", gap = 1 },
  },
  preview_wanted_left = {
    category = "preview",
    label = "Wanted Left",
    theme = "wanted",
    cmd = ":e lua/wildest/renderer/components/",
    noselect = false,
    preview = { position = "left", anchor = "popup", width = "60%", border = "rounded", gap = 1 },
  },
  preview_wanted_top = {
    category = "preview",
    label = "Wanted Top",
    theme = "wanted",
    cmd = ":e lua/wildest/renderer/components/",
    noselect = false,
    preview = { position = "top", anchor = "popup", height = "60%", border = "rounded", gap = 1 },
  },
  preview_wanted_bottom = {
    category = "preview",
    label = "Wanted Bottom",
    theme = "wanted",
    cmd = ":e lua/wildest/renderer/components/",
    noselect = false,
    preview = { position = "bottom", anchor = "popup", height = "60%", border = "rounded", gap = 1 },
  },

  -- Gap configs: showcase gap spacing between preview, popup, and screen edges.
  preview_gap_right = {
    category = "preview",
    label = "Gap Right",
    theme = "wanted",
    cmd = ":e lua/wildest/renderer/components/",
    noselect = false,
    preview = { position = "right", anchor = "popup", width = "50%", border = "rounded", gap = 2 },
  },
  preview_gap_left = {
    category = "preview",
    label = "Gap Left",
    theme = "wanted",
    cmd = ":e lua/wildest/renderer/components/",
    noselect = false,
    preview = { position = "left", anchor = "popup", width = "50%", border = "rounded", gap = 2 },
  },
  preview_gap_screen_right = {
    category = "preview",
    label = "Gap Screen Right",
    cmd = ":e lua/wildest/renderer/components/",
    noselect = false,
    preview = { position = "right", anchor = "screen", width = "40%", border = "rounded", gap = 2 },
  },
  preview_gap_screen_left = {
    category = "preview",
    label = "Gap Screen Left",
    cmd = ":e lua/wildest/renderer/components/",
    noselect = false,
    preview = { position = "left", anchor = "screen", width = "40%", border = "rounded", gap = 2 },
  },

  -- Priority configs: preview gets full configured size, menu adapts.
  preview_priority_right = {
    category = "preview",
    label = "Priority Right",
    theme = "wanted",
    cmd = ":e lua/wildest/renderer/components/",
    noselect = false,
    preview = { position = "right", anchor = "popup", width = "60%", border = "rounded", gap = 1, priority = "preview" },
  },
  preview_priority_screen = {
    category = "preview",
    label = "Priority Screen",
    cmd = ":e lua/wildest/renderer/components/",
    noselect = false,
    preview = { position = "right", anchor = "screen", width = "40%", border = "rounded", priority = "preview" },
  },
}

-- Default VHS command for configs that don't specify one
M.default_cmd = ":set fold"

-- Ordered name lists (single source of truth for README generation + generate.sh)
M.renderer_names = { "popupmenu", "popupmenu_border", "popupmenu_palette", "palette_prompt_bottom", "wildmenu" }
M.feature_names = {
  "devicons", "fuzzy", "gradient", "search", "fuzzy_search", "renderer_mux",
  "kind_icons", "cmdline_icon", "cmdline_icon_help", "prefix_highlighter",
  "scrollbar", "pumblend", "chain_highlighter", "scrollbar_collapse",
}
M.pipeline_names = { "lua_pipeline", "help_pipeline", "history_pipeline", "shell_pipeline", "substitute_pipeline", "history_prefix_pipeline" }
M.highlight_names = { "hl_neon", "hl_ember", "hl_ocean" }
M.border_names = { "border_rounded", "border_single", "border_double", "border_solid", "border_title" }
M.wildmenu_variant_names = { "wildmenu_dot", "wildmenu_reverse", "wildmenu_minimal", "wildmenu_pipe", "wildmenu_arrows_index", "wildmenu_compact", "wildmenu_powerline" }
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
  "top_component", "bottom_component", "top_bottom_components",
  "before_cursor", "sort_buffers_lastused",
}
M.preview_names = {
  "preview_right_screen", "preview_left_screen", "preview_top_screen", "preview_bottom_screen",
  "preview_right_popup", "preview_left_popup", "preview_top_popup", "preview_bottom_popup",
  "preview_wanted_right", "preview_wanted_left", "preview_wanted_top", "preview_wanted_bottom",
  "preview_gap_right", "preview_gap_left", "preview_gap_screen_right", "preview_gap_screen_left",
  "preview_priority_right", "preview_priority_screen",
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

-- ── Categories (ordered, used by generate.lua CLI + list) ──────

M.categories = {
  { flag = "renderers",         display = "Renderers",         names = M.renderer_names },
  { flag = "themes",            display = "Themes",            names = M.theme_names, prefix = "theme_" },
  { flag = "features",          display = "Features",          names = M.feature_names },
  { flag = "pipelines",         display = "Pipelines",         names = M.pipeline_names },
  { flag = "highlights",        display = "Highlights",        names = M.highlight_names },
  { flag = "borders",           display = "Borders",           names = M.border_names },
  { flag = "wildmenu-variants", display = "Wildmenu Variants", names = M.wildmenu_variant_names },
  { flag = "palette-variants",  display = "Palette Variants",  names = M.palette_variant_names },
  { flag = "dimensions",        display = "Dimensions",        names = M.dimension_names },
  { flag = "gradients",         display = "Gradients",         names = M.gradient_names },
  { flag = "combinations",      display = "Combinations",      names = M.combination_names },
  { flag = "layouts",           display = "Layouts",           names = M.layout_names },
  { flag = "options",           display = "Options",           names = M.option_names },
  { flag = "previews",          display = "Previews",          names = M.preview_names },
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
    { "cmdline_fuzzy", "search_fuzzy" },
    { "lua", "cmdline_fuzzy", "search" },
    { "help_fuzzy", "cmdline_fuzzy", "search_fuzzy" },
    { "history", "cmdline_fuzzy", "search" },
    { "history_prefix", "cmdline_fuzzy", "search" },
    { "shell_fuzzy", "cmdline_fuzzy", "search" },
    { "substitute", "cmdline_fuzzy", "search" },
    { "substitute", "cmdline_fuzzy", "search_fuzzy" },
  }
  local lefts = {
    {},
    { "devicons" },
    { "kind_icon" },
    { "cmdline_icon" },
    { "devicons", "kind_icon" },
    { "cmdline_icon", "devicons" },
    { "buffer_flags" },
  }
  local rights = {
    { "scrollbar" },
    { "scrollbar_collapse" },
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
  if math.random(6) == 1 then
    scene.empty_message_first_draw_delay = pick({ 100, 200, 500 })
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
  if math.random(6) == 1 then
    scene.hooks = pick({ "enter", "leave", "draw", "enter+leave", "enter+draw", "results", "select", "select+accept" })
  end
  if recipe == "theme" then
    scene.renderer = "theme:" .. pick(M._random_themes)
    scene.left = pick(lefts)
    scene.right = pick(rights)
    scene.highlighter = pick(highlighters)

  elseif recipe == "wildmenu" then
    scene.renderer = "wildmenu"
    scene.highlighter = pick(highlighters)
    scene.separator = pick({ " | ", "  ", " · ", "powerline" })
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

-- ── Showdown scene generation ────────────────────────────────────

local showdown_file_cmds = {
  { mode = ":", typed = "e lua/wildest/renderer/components/" },
  { mode = ":", typed = "e tests/" },
  { mode = ":", typed = "e lua/wildest/" },
  { mode = ":", typed = "e lua/wildest/renderer/" },
  { mode = ":", typed = "e scripts/" },
  { mode = ":", typed = "e tests/test_c" },
}

local showdown_search_cmds = {
  { mode = "/", typed = "function" },
  { mode = "/", typed = "return" },
  { mode = "/", typed = "local" },
  { mode = "/", typed = "require" },
}

-- Actions cycle deterministically so every type gets showcased; the action
-- itself is secondary — the star of showdown is the preview + config variety.
local showdown_action_cycle = {
  "accept",
  "open_split",
  "open_vsplit",
  "open_tab",
  "send_to_quickfix",
  "send_to_loclist",
  "toggle_preview",
  "redirect_output",
  "search_accept",
}

--- Generate a deterministic showdown scene plan.
--- Each entry has the VHS command, action, and how many candidates to browse
--- before settling (so the viewer sees the preview updating across selections).
--- Both generate.lua (VHS tape) and gif_init (config) use the same seed.
---@param n number
---@param seed number  deterministic seed for math.random
---@return table[]  list of { vhs_cmd, action, browse_count }
function M.showdown_scene_plan(n, seed)
  math.randomseed(seed)
  local plan = {}
  for i = 1, n do
    local action = showdown_action_cycle[((i - 1) % #showdown_action_cycle) + 1]
    local vhs_cmd
    if action == "search_accept" then
      vhs_cmd = pick(showdown_search_cmds)
    else
      vhs_cmd = pick(showdown_file_cmds)
    end
    local browse_count = math.random(2, 5)
    table.insert(plan, { vhs_cmd = vhs_cmd, action = action, browse_count = browse_count })
  end
  return plan
end

--- Generate full showdown scenes with random configs, preview, and actions.
--- Uses WILDEST_GIF_SEED env var for seed synchronization with VHS tape.
---@param n number
---@return table[]
function M.showdown_scenes(n)
  local seed = tonumber(os.getenv("WILDEST_GIF_SEED")) or (os.time() + (vim.fn.getpid and vim.fn.getpid() or 0))
  local plan = M.showdown_scene_plan(n, seed)

  -- Re-seed for the config randomization (independent of the plan seed)
  math.randomseed(seed + 1)

  local borders = { "rounded", "single", "double", "solid" }
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
    local scene = M.random_scene(label)

    -- Always add preview
    local pos = pick({ "right", "left", "top", "bottom" })
    local anchor = pick({ "screen", "popup" })
    local dim = (pos == "right" or pos == "left") and "width" or "height"
    scene.preview = { position = pos, anchor = anchor, [dim] = pick({ "30%", "40%", "50%" }), border = pick(borders) }

    -- Add default actions keymaps
    scene.actions = {
      ["<C-t>"] = "open_tab",
      ["<C-s>"] = "open_split",
      ["<C-v>"] = "open_vsplit",
      ["<C-q>"] = "send_to_quickfix",
      ["<C-l>"] = "send_to_loclist",
      ["<C-p>"] = "toggle_preview",
      ["<C-r>"] = "redirect_output",
    }

    -- Copy plan metadata
    scene.action = plan[i].action
    scene.vhs_cmd = plan[i].vhs_cmd

    table.insert(scenes, scene)
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
---@param add fun(s: string)
local function setup_block_lines(cfg, add)
  add("require('wildest').setup({")

  -- Core fields
  local field_order = {
    "renderer", "pipeline", "highlighter",
    "padding", "left", "right", "top", "bottom", "separator", "ellipsis",
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

  -- Preview sub-table
  if cfg.preview then
    add("  preview = {")
    for k, v in pairs(cfg.preview) do
      add("    " .. k .. " = " .. fmt_val(v) .. ",")
    end
    add("  },")
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

  -- Hook examples (shown as API calls after setup)
  if cfg.hooks then
    add("")
    local hook_str = cfg.hooks
    if hook_str:find("enter") then
      add("w.on('enter', function(cmdtype)")
      add("  vim.o.statusline = ' wildest [' .. cmdtype .. '] '")
      add("end)")
    end
    if hook_str:find("leave") then
      add("w.on('leave', function()")
      add("  vim.o.statusline = ' %f %m%= '")
      add("end)")
    end
    if hook_str:find("draw") then
      add("w.on('draw', function(ctx, result)")
      add("  -- ctx.selected, result.value")
      add("end)")
    end
    if hook_str:find("results") then
      add("w.on('results', function(ctx, result)")
      add("  -- result.value contains candidates")
      add("end)")
    end
    if hook_str:find("select") then
      add("w.on('select', function(ctx, candidate, index)")
      add("  -- candidate selected at index")
      add("end)")
    end
    if hook_str:find("accept") then
      add("w.on('accept', function(ctx, candidate)")
      add("  -- completion accepted")
      add("end)")
    end
  end
end

-- Sample Lua code appended to screenshot buffers so search-mode
-- screenshots and GIF scenes (cmd = "/function", "/self", etc.)
-- find matches in the buffer.  Every search term used in scene_pools
-- (generate.lua) and screenshot configs must appear here.
local sample_lua_lines = {
  "",
  "-- Example: custom pipeline stage",
  "local function my_filter(self, ctx, candidates)",
  "  local result = {}",
  "  for _, candidate in ipairs(candidates) do",
  "    local str = tostring(candidate)",
  "    if not string.match(str, '^_') then",
  "      table.insert(result, candidate)",
  "    end",
  "  end",
  "  return result",
  "end",
  "",
  "-- Example: conditional renderer",
  "local function setup_renderer(self, opts)",
  "  local renderer = require('wildest').popupmenu_border({",
  "    border = opts.border or 'rounded',",
  "    max_height = opts.max_height or 12,",
  "    left = { require('wildest').popupmenu_devicons() },",
  "    right = { require('wildest').popupmenu_scrollbar() },",
  "  })",
  "  return renderer",
  "end",
}

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

  setup_block_lines(scene, add)

  for _, line in ipairs(sample_lua_lines) do
    add(line)
  end

  return lines
end

--- Convert a scene/config table to comma-separated description (like screenshots).
---@param cfg table scene or config table
---@return string
function M.scene_to_description(cfg)
  if not cfg then
    return ""
  end
  local merged = vim.tbl_extend("keep", cfg, M.defaults)
  if merged.theme then
    merged.renderer = "theme:" .. merged.theme
    merged.highlights = false
  end

  local tokens = {}
  local function add(s) tokens[#tokens + 1] = s end

  local renderer = merged.renderer or "theme:auto"
  if renderer == "popupmenu" then
    add("plain popupmenu")
  elseif renderer == "border_theme" then
    add("bordered")
  elseif renderer == "palette" then
    add("palette")
  elseif renderer == "wildmenu" then
    add("wildmenu")
  elseif renderer == "mux" then
    add("renderer mux")
  elseif renderer:match("^theme:") then
    local theme_name = renderer:match("^theme:(.+)$")
    add(theme_name .. " theme")
    if M.theme_meta[theme_name] then
      add(M.theme_meta[theme_name].renderer)
    end
  end

  if merged.border then
    add(merged.border)
  end

  if merged.title then add("title") end
  if merged.position and merged.position ~= "bottom" then
    add("position=" .. merged.position)
  end
  if merged.reverse then add("reverse") end
  if merged.noselect == true then add("noselect") end
  if merged.noselect == false then add("noselect=false") end
  if merged.pumblend then add("pumblend=" .. merged.pumblend) end
  if merged.offset then add("offset=" .. merged.offset) end
  if merged.max_height then add("max_height=" .. merged.max_height) end
  if merged.min_height then add("min_height=" .. merged.min_height) end
  if merged.fixed_height == false then add("fixed_height=false") end
  if merged.empty_message then add("empty_message") end
  if merged.empty_message_first_draw_delay then add("empty_delay=" .. merged.empty_message_first_draw_delay .. "ms") end
  if merged.ellipsis then add("ellipsis") end
  if merged.top and #merged.top > 0 then add("top") end
  if merged.bottom and #merged.bottom > 0 then add("bottom") end

  add(merged.highlighter or "fzy")

  local left = merged.left
  local has_devicons, has_kind, has_buffer_flags, has_cmdline_icon = false, false, false, false
  if type(left) == "string" then
    if left == "devicons" then has_devicons = true end
  elseif type(left) == "table" then
    for _, item in ipairs(left) do
      if item == "devicons" then has_devicons = true end
      if item == "kind_icon" then has_kind = true end
      if item == "buffer_flags" then has_buffer_flags = true end
      if item == "cmdline_icon" then has_cmdline_icon = true end
    end
  end
  if has_devicons then add("devicons") end
  if has_kind then add("kind icons") end
  if has_cmdline_icon then add("cmdline icon") end
  if has_buffer_flags then add("buffer flags") end
  if not has_devicons and M.defaults.left == "devicons"
    and renderer ~= "wildmenu" and renderer ~= "mux" then
    add("no devicons")
  end

  local has_scrollbar = false
  local has_scrollbar_collapse = false
  if type(merged.right) == "table" then
    for _, item in ipairs(merged.right) do
      if item == "scrollbar" then has_scrollbar = true end
      if item == "scrollbar_collapse" then has_scrollbar_collapse = true; has_scrollbar = true end
    end
  end
  if has_scrollbar_collapse then
    add("scrollbar(collapse)")
  elseif has_scrollbar then
    add("scrollbar")
  end
  local default_has_scrollbar = false
  if type(M.defaults.right) == "table" then
    for _, item in ipairs(M.defaults.right) do
      if item == "scrollbar" then default_has_scrollbar = true end
    end
  end
  if not has_scrollbar and default_has_scrollbar
    and renderer ~= "wildmenu" and renderer ~= "mux" then
    add("no scrollbar")
  end

  if renderer == "wildmenu" then
    local has_arrows = false
    if type(left) == "table" then
      for _, item in ipairs(left) do
        if item == "arrows" then has_arrows = true end
      end
    end
    if type(merged.right) == "table" then
      for _, item in ipairs(merged.right) do
        if item == "arrows_right" then has_arrows = true end
      end
    end
    if has_arrows then add("arrows") end
    if type(merged.right) == "table" then
      for _, item in ipairs(merged.right) do
        if item == "index" then add("index"); break end
      end
    end
    if merged.separator then
      if type(merged.separator) == "string" then
        add('separator="' .. merged.separator .. '"')
      else
        add("separator=powerline")
      end
    end
  end

  if merged.pipeline then
    for _, p in ipairs(merged.pipeline) do
      if p == "lua" then add("lua pipeline") end
      if p == "help_fuzzy" then add("help pipeline") end
      if p == "history" then add("history pipeline") end
      if p == "history_prefix" then add("history prefix pipeline") end
      if p == "shell" or p == "shell_fuzzy" then add("shell pipeline") end
      if p == "substitute" then add("substitute pipeline") end
      if p == "search_fuzzy" then add("fuzzy search") end
      if p == "cmdline_fuzzy_before_cursor" then add("before_cursor") end
      if p == "cmdline_buffers_lastused" then add("sort_buffers_lastused") end
    end
  end

  if merged.laststatus ~= M.defaults.laststatus then
    add("laststatus=" .. merged.laststatus)
  end
  if merged.cmdheight ~= M.defaults.cmdheight then
    add("cmdheight=" .. merged.cmdheight)
  end

  if merged.preview then
    local p = merged.preview
    local desc = "preview " .. (p.position or "right") .. " " .. (p.anchor or "screen")
    if p.gap then
      desc = desc .. " gap=" .. (type(p.gap) == "number" and p.gap or "table")
    end
    add(desc)
  end

  if merged.hooks then
    add("hooks=" .. merged.hooks)
  end

  if merged.action then add("action: " .. merged.action) end

  if merged.custom_highlights then add("custom highlights") end
  if merged.gradient_colors then add("gradient colors") end

  return table.concat(tokens, ", ")
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

  setup_block_lines(cfg, add)

  for _, line in ipairs(sample_lua_lines) do
    add(line)
  end

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
    elseif name == "search_fuzzy" then
      table.insert(branches, w.search_pipeline({ fuzzy = true }))
    elseif name == "lua" then
      table.insert(branches, w.lua_pipeline())
    elseif name == "help_fuzzy" then
      table.insert(branches, w.help_pipeline({ fuzzy = true }))
    elseif name == "history" then
      table.insert(branches, w.history_pipeline())
    elseif name == "history_prefix" then
      table.insert(branches, w.history_pipeline({ prefix = true }))
    elseif name == "shell" then
      table.insert(branches, w.shell_pipeline())
    elseif name == "shell_fuzzy" then
      table.insert(branches, w.shell_pipeline({ fuzzy = true }))
    elseif name == "substitute" then
      table.insert(branches, w.substitute_pipeline())
    elseif name == "cmdline_fuzzy_before_cursor" then
      table.insert(branches, w.cmdline_pipeline({ fuzzy = true, before_cursor = true }))
    elseif name == "cmdline_buffers_lastused" then
      table.insert(branches, w.cmdline_pipeline({ fuzzy = true, sort_buffers_lastused = true }))
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
  elseif name == "scrollbar_collapse" then
    return w.popupmenu_scrollbar({ collapse = true })
  elseif name == "arrows" then
    return w.wildmenu_arrows()
  elseif name == "arrows_right" then
    return w.wildmenu_arrows({ right = true })
  elseif name == "index" then
    return w.wildmenu_index()
  elseif name == "kind_icon" then
    return w.popupmenu_kind_icon()
  elseif name == "cmdline_icon" then
    return w.popupmenu_cmdline_icon()
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
  elseif name == "chain" then
    return w.chain_highlighter({ w.fzy_highlighter(), w.basic_highlighter() })
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
    if cfg.separator == "powerline" then
      opts.separator = w.wildmenu_powerline_separator()
    else
      opts.separator = cfg.separator
    end
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
  if cfg.empty_message_first_draw_delay then
    opts.empty_message_first_draw_delay = cfg.empty_message_first_draw_delay
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
  if cfg.top then
    opts.top = cfg.top
  end
  if cfg.bottom then
    opts.bottom = cfg.bottom
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
    local theme = M._random_themes[math.random(#M._random_themes)]
    merged.renderer = "theme:" .. theme
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
  if merged.preview then
    setup_opts.preview = merged.preview
  end
  if merged.actions then
    setup_opts.actions = merged.actions
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

  -- Create dummy buffers for configs that use buffer completion (:b)
  local cfg = M.configs[config_name]
  if cfg and cfg.cmd and cfg.cmd:match("^:b ") then
    local dummy_names = {
      "lua/wildest/init.lua",
      "lua/wildest/cache.lua",
      "lua/wildest/renderer/popupmenu.lua",
      "lua/wildest/pipeline/init.lua",
      "tests/test_cache.lua",
    }
    for _, name in ipairs(dummy_names) do
      vim.cmd.badd(name)
    end
  end

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
  local scenes
  if name == "showdown" then
    scenes = M.showdown_scenes(n)
  else
    scenes = M.random_scenes(n)
  end

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
    local desc = M.scene_to_description(scene)
    local buf_name = desc ~= "" and ("[" .. desc .. "]") or ("[Scene " .. index .. "]")
    vim.api.nvim_buf_set_name(0, buf_name)
    vim.o.statusline = " %f %= [" .. index .. "/" .. #scenes .. " - " .. (scene.label or "") .. "] "

    -- Write scene config as buffer content
    local lines = M.scene_to_lines(scene, index, #scenes)
    vim.bo.readonly = false
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
