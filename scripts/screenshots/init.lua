-- Screenshot init for wildest.nvim
-- Usage: WILDEST_CONFIG=theme_saloon nvim -u scripts/screenshots/init.lua sample.lua
--
-- Reads WILDEST_CONFIG env var to select which configuration variant to use.
-- See generate.sh for the list of all available configs.

-- Add this plugin to rtp
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h:h")
vim.opt.rtp:prepend(root)

-- Optionally add nvim-web-devicons for devicons screenshots
local devicons_path = root .. "/deps/nvim-web-devicons"
if vim.fn.isdirectory(devicons_path) == 1 then
  vim.opt.rtp:prepend(devicons_path)
end

-- Add kanagawa colorscheme if available
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

-- Clean environment for screenshots
vim.o.swapfile = false
vim.o.shadafile = "NONE"
vim.o.number = true
vim.o.relativenumber = true
vim.o.signcolumn = "yes"
vim.o.termguicolors = true
vim.o.showmode = false
vim.o.ruler = false
vim.o.laststatus = 2
vim.o.cmdheight = 1
vim.o.cursorline = true
vim.o.scrolloff = 8

-- Use kanagawa as the background colorscheme
local ok = pcall(vim.cmd, "colorscheme kanagawa")
if not ok then
  vim.cmd("colorscheme habamax")
end

local w = require("wildest")

local config_name = vim.env.WILDEST_CONFIG or vim.g.wildest_config or "popupmenu_border"

-- Helper: check if devicons is available
local has_devicons = pcall(require, "nvim-web-devicons")

-- Helper: build left components with optional devicons
local function left_with_devicons()
  if has_devicons then
    return { " ", w.popupmenu_devicons() }
  end
  return { " " }
end

-- ── Renderer configs ──────────────────────────────────────────────

local configs = {}

-- Plain popupmenu (no border)
configs.popupmenu = {
  pipeline = w.branch(w.cmdline_pipeline({ fuzzy = true }), w.search_pipeline()),
  renderer = w.popupmenu_renderer({
    highlighter = w.basic_highlighter(),
    left = { " " },
    right = { " ", w.popupmenu_scrollbar() },
  }),
}

-- Bordered popupmenu
configs.popupmenu_border = function()
  return {
    pipeline = w.branch(w.cmdline_pipeline({ fuzzy = true }), w.search_pipeline()),
    renderer = w.theme("auto").renderer({
      highlighter = w.fzy_highlighter(),
      left = left_with_devicons(),
      right = { " ", w.popupmenu_scrollbar() },
    }),
  }
end

-- Centered palette
configs.popupmenu_palette = function()
  return {
    pipeline = w.branch(w.cmdline_pipeline({ fuzzy = true }), w.search_pipeline()),
    renderer = w.extend_theme("auto", {
      renderer = "palette",
      renderer_opts = {
        title = " Wildest ",
        prompt_prefix = " : ",
        prompt_position = "top",
        max_height = "60%",
        max_width = "60%",
        min_width = 40,
        margin = "auto",
      },
    }).renderer({
      highlighter = w.fzy_highlighter(),
      left = { " " },
      right = { " ", w.popupmenu_scrollbar() },
    }),
  }
end

-- Horizontal wildmenu
configs.wildmenu = {
  pipeline = w.branch(w.cmdline_pipeline({ fuzzy = true }), w.search_pipeline()),
  renderer = w.wildmenu_renderer({
    highlighter = w.basic_highlighter(),
    separator = " | ",
    left = { w.wildmenu_arrows() },
    right = { w.wildmenu_arrows({ right = true }), " ", w.wildmenu_index() },
  }),
}

-- ── Feature configs ───────────────────────────────────────────────

-- Devicons showcase
configs.devicons = function()
  return {
    pipeline = w.branch(w.cmdline_pipeline({ fuzzy = true }), w.search_pipeline()),
    renderer = w.theme("auto").renderer({
      highlighter = w.fzy_highlighter(),
      left = { " ", w.popupmenu_devicons() },
      right = { " ", w.popupmenu_scrollbar() },
    }),
  }
end

-- Fuzzy matching showcase
configs.fuzzy = function()
  return {
    pipeline = w.branch(w.cmdline_pipeline({ fuzzy = true }), w.search_pipeline()),
    renderer = w.theme("auto").renderer({
      highlighter = w.fzy_highlighter(),
      left = { " " },
      right = { " ", w.popupmenu_scrollbar() },
    }),
  }
end

-- Gradient highlighting
configs.gradient = function()
  local gradient = {}
  for i = 0, 15 do
    local name = "WildestGradient" .. i
    vim.api.nvim_set_hl(0, name, {
      fg = string.format("#%02x%02x%02x", 255 - i * 16, 100 + i * 8, i * 16),
    })
    table.insert(gradient, name)
  end
  return {
    pipeline = w.branch(w.cmdline_pipeline({ fuzzy = true }), w.search_pipeline()),
    renderer = w.theme("auto").renderer({
      highlighter = w.gradient_highlighter(w.basic_highlighter(), gradient),
      left = { " " },
      right = { " ", w.popupmenu_scrollbar() },
    }),
  }
end

-- Search mode showcase
configs.search = function()
  return {
    pipeline = w.branch(w.cmdline_pipeline({ fuzzy = true }), w.search_pipeline()),
    renderer = w.theme("auto").renderer({
      highlighter = w.basic_highlighter(),
      left = { " " },
      right = { " ", w.popupmenu_scrollbar() },
    }),
  }
end

-- Renderer mux (different renderers for : vs /)
configs.renderer_mux = function()
  return {
    pipeline = w.branch(w.cmdline_pipeline({ fuzzy = true }), w.search_pipeline()),
    renderer = w.renderer_mux({
      [":"] = w.theme("auto").renderer({
        highlighter = w.fzy_highlighter(),
        left = left_with_devicons(),
        right = { " ", w.popupmenu_scrollbar() },
      }),
      ["/"] = w.wildmenu_renderer({
        highlighter = w.basic_highlighter(),
        separator = " | ",
      }),
    }),
  }
end

-- ── Custom highlight configs ──────────────────────────────────────

-- Neon: bright cyberpunk-inspired highlights
configs.hl_neon = function()
  vim.api.nvim_set_hl(0, "WildestDefault", { bg = "#0d0d1a", fg = "#e0e0ff" })
  vim.api.nvim_set_hl(0, "WildestSelected", { bg = "#1a0a2e", fg = "#ffffff", bold = true })
  vim.api.nvim_set_hl(0, "WildestAccent", { bg = "#0d0d1a", fg = "#00ffcc", bold = true })
  vim.api.nvim_set_hl(0, "WildestSelectedAccent", { bg = "#1a0a2e", fg = "#ff00ff", bold = true })
  vim.api.nvim_set_hl(0, "WildestBorder", { bg = "#0d0d1a", fg = "#6644ff" })
  vim.api.nvim_set_hl(0, "WildestScrollbar", { bg = "#0d0d1a" })
  vim.api.nvim_set_hl(0, "WildestScrollbarThumb", { bg = "#6644ff" })
  return {
    pipeline = w.branch(w.cmdline_pipeline({ fuzzy = true }), w.search_pipeline()),
    renderer = w.popupmenu_border_theme({
      border = "rounded",
      highlighter = w.fzy_highlighter(),
      left = left_with_devicons(),
      right = { " ", w.popupmenu_scrollbar() },
    }),
  }
end

-- Ember: warm orange and red tones
configs.hl_ember = function()
  vim.api.nvim_set_hl(0, "WildestDefault", { bg = "#1a0f0a", fg = "#e8c8a0" })
  vim.api.nvim_set_hl(0, "WildestSelected", { bg = "#2d1810", fg = "#ffe0b0", bold = true })
  vim.api.nvim_set_hl(0, "WildestAccent", { bg = "#1a0f0a", fg = "#ff6622", bold = true })
  vim.api.nvim_set_hl(0, "WildestSelectedAccent", { bg = "#2d1810", fg = "#ffaa44", bold = true })
  vim.api.nvim_set_hl(0, "WildestBorder", { bg = "#120a06", fg = "#884422" })
  vim.api.nvim_set_hl(0, "WildestScrollbar", { bg = "#1a0f0a" })
  vim.api.nvim_set_hl(0, "WildestScrollbarThumb", { bg = "#884422" })
  return {
    pipeline = w.branch(w.cmdline_pipeline({ fuzzy = true }), w.search_pipeline()),
    renderer = w.popupmenu_border_theme({
      border = "rounded",
      highlighter = w.fzy_highlighter(),
      left = left_with_devicons(),
      right = { " ", w.popupmenu_scrollbar() },
    }),
  }
end

-- Ocean: cool blue and teal tones
configs.hl_ocean = function()
  vim.api.nvim_set_hl(0, "WildestDefault", { bg = "#0a1520", fg = "#b0d0e8" })
  vim.api.nvim_set_hl(0, "WildestSelected", { bg = "#102030", fg = "#d0e8ff", bold = true })
  vim.api.nvim_set_hl(0, "WildestAccent", { bg = "#0a1520", fg = "#00bbdd", bold = true })
  vim.api.nvim_set_hl(0, "WildestSelectedAccent", { bg = "#102030", fg = "#44ddff", bold = true })
  vim.api.nvim_set_hl(0, "WildestBorder", { bg = "#061018", fg = "#226688" })
  vim.api.nvim_set_hl(0, "WildestScrollbar", { bg = "#0a1520" })
  vim.api.nvim_set_hl(0, "WildestScrollbarThumb", { bg = "#226688" })
  return {
    pipeline = w.branch(w.cmdline_pipeline({ fuzzy = true }), w.search_pipeline()),
    renderer = w.popupmenu_border_theme({
      border = "rounded",
      highlighter = w.fzy_highlighter(),
      left = left_with_devicons(),
      right = { " ", w.popupmenu_scrollbar() },
    }),
  }
end

-- ── Theme configs ─────────────────────────────────────────────────

local theme_names = {
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
}

-- Theme configs are lazy: store factory functions so only the selected
-- theme applies its highlights (they all share the same group names).
for _, name in ipairs(theme_names) do
  configs["theme_" .. name] = function()
    return {
      pipeline = w.branch(w.cmdline_pipeline({ fuzzy = true }), w.search_pipeline()),
      renderer = w.theme(name).renderer({
        highlighter = w.fzy_highlighter(),
        left = left_with_devicons(),
        right = { " ", w.popupmenu_scrollbar() },
      }),
    }
  end
end

-- ── Apply selected config ─────────────────────────────────────────

local cfg = configs[config_name]
if not cfg then
  vim.notify("[screenshots] Unknown config: " .. config_name, vim.log.levels.ERROR)
  vim.notify(
    "[screenshots] Available: " .. table.concat(vim.tbl_keys(configs), ", "),
    vim.log.levels.INFO
  )
  cfg = configs.popupmenu_border
end

-- Resolve lazy configs (theme factories)
if type(cfg) == "function" then
  cfg = cfg()
end

w.setup(vim.tbl_extend("force", {
  modes = { ":", "/", "?" },
  next_key = "<Tab>",
  previous_key = "<S-Tab>",
  accept_key = "<Down>",
  reject_key = "<Up>",
}, cfg))
