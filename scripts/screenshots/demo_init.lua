-- Demo init for wildest.nvim animated GIF
-- Single Neovim session that cycles through configs via <F12>.
-- Usage: nvim -u scripts/screenshots/demo_init.lua scripts/screenshots/sample.lua

local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h:h")
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
vim.o.laststatus = 2
vim.o.cmdheight = 1
vim.o.cursorline = true
vim.o.scrolloff = 8

local ok = pcall(vim.cmd, "colorscheme kanagawa")
if not ok then
  vim.cmd("colorscheme habamax")
end

local w = require("wildest")

local has_devicons = pcall(require, "nvim-web-devicons")

local function left_with_devicons()
  if has_devicons then
    return { " ", w.popupmenu_devicons() }
  end
  return { " " }
end

-- Shared accent highlights for all demo scenes
local demo_highlights = {
  accent = "IncSearch",
  selected_accent = "IncSearch",
}

-- ── Demo scene configs (order matters) ──────────────────────────

local scenes = {}

-- 1. Devicons: file completion with icons
scenes[#scenes + 1] = {
  name = "devicons",
  config = function()
    return {
      pipeline = w.branch(w.cmdline_pipeline({ fuzzy = true }), w.search_pipeline()),
      renderer = w.theme("auto").renderer({
        highlighter = w.fzy_highlighter(),
        highlights = demo_highlights,
        left = { " ", has_devicons and w.popupmenu_devicons() or nil },
        right = { " ", w.popupmenu_scrollbar() },
      }),
    }
  end,
}

-- 2. Fuzzy matching
scenes[#scenes + 1] = {
  name = "fuzzy",
  config = function()
    return {
      pipeline = w.branch(w.cmdline_pipeline({ fuzzy = true }), w.search_pipeline()),
      renderer = w.theme("auto").renderer({
        highlighter = w.fzy_highlighter(),
        highlights = demo_highlights,
        left = { " " },
        right = { " ", w.popupmenu_scrollbar() },
      }),
    }
  end,
}

-- 3. Search pipeline
scenes[#scenes + 1] = {
  name = "search",
  config = function()
    return {
      pipeline = w.branch(w.cmdline_pipeline({ fuzzy = true }), w.search_pipeline()),
      renderer = w.theme("auto").renderer({
        highlighter = w.basic_highlighter(),
        highlights = demo_highlights,
        left = { " " },
        right = { " ", w.popupmenu_scrollbar() },
      }),
    }
  end,
}

-- 4. Lua pipeline
scenes[#scenes + 1] = {
  name = "lua_pipeline",
  config = function()
    return {
      pipeline = w.branch(w.lua_pipeline(), w.cmdline_pipeline({ fuzzy = true })),
      renderer = w.theme("auto").renderer({
        highlighter = w.fzy_highlighter(),
        highlights = demo_highlights,
        left = left_with_devicons(),
        right = { " ", w.popupmenu_scrollbar() },
      }),
    }
  end,
}

-- 5. Help pipeline
scenes[#scenes + 1] = {
  name = "help_pipeline",
  config = function()
    return {
      pipeline = w.branch(w.help_pipeline({ fuzzy = true }), w.cmdline_pipeline({ fuzzy = true })),
      renderer = w.theme("auto").renderer({
        highlighter = w.fzy_highlighter(),
        highlights = demo_highlights,
        left = left_with_devicons(),
        right = { " ", w.popupmenu_scrollbar() },
      }),
    }
  end,
}

-- 6. Gradient highlighting
scenes[#scenes + 1] = {
  name = "gradient",
  config = function()
    local rainbow = {
      "#ff0000", "#ff4400", "#ff8800", "#ffcc00",
      "#ffff00", "#88ff00", "#00ff44", "#00ffaa",
      "#00ffff", "#00aaff", "#0044ff", "#4400ff",
      "#8800ff", "#cc00ff", "#ff00ff", "#ff0088",
    }
    local gradient = {}
    for i, color in ipairs(rainbow) do
      local name = "WildestGradient" .. i
      vim.api.nvim_set_hl(0, name, { fg = color, bold = true })
      table.insert(gradient, name)
    end
    return {
      pipeline = w.branch(w.cmdline_pipeline({ fuzzy = true }), w.search_pipeline()),
      renderer = w.theme("auto").renderer({
        highlighter = w.gradient_highlighter(w.fzy_highlighter(), gradient),
        left = { " " },
        right = { " ", w.popupmenu_scrollbar() },
      }),
    }
  end,
}

-- 7. Palette renderer
scenes[#scenes + 1] = {
  name = "palette",
  config = function()
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
        highlights = demo_highlights,
        left = { " " },
        right = { " ", w.popupmenu_scrollbar() },
      }),
    }
  end,
}

-- 8. Wildmenu renderer
scenes[#scenes + 1] = {
  name = "wildmenu",
  config = function()
    return {
      pipeline = w.branch(w.cmdline_pipeline({ fuzzy = true }), w.search_pipeline()),
      renderer = w.wildmenu_renderer({
        highlighter = w.basic_highlighter(),
        highlights = demo_highlights,
        separator = " | ",
        left = { w.wildmenu_arrows() },
        right = { w.wildmenu_arrows({ right = true }), " ", w.wildmenu_index() },
      }),
    }
  end,
}

-- 9. History pipeline
scenes[#scenes + 1] = {
  name = "history_pipeline",
  config = function()
    return {
      pipeline = w.branch(w.history_pipeline(), w.cmdline_pipeline({ fuzzy = true })),
      renderer = w.theme("auto").renderer({
        highlighter = w.fzy_highlighter(),
        highlights = demo_highlights,
        left = { " " },
        right = { " ", w.popupmenu_scrollbar() },
      }),
    }
  end,
}

-- 10. Renderer mux (bordered popup for :, wildmenu for /)
scenes[#scenes + 1] = {
  name = "renderer_mux",
  config = function()
    return {
      pipeline = w.branch(w.cmdline_pipeline({ fuzzy = true }), w.search_pipeline()),
      renderer = w.renderer_mux({
        [":"] = w.theme("auto").renderer({
          highlighter = w.fzy_highlighter(),
          highlights = demo_highlights,
          left = left_with_devicons(),
          right = { " ", w.popupmenu_scrollbar() },
        }),
        ["/"] = w.wildmenu_renderer({
          highlighter = w.basic_highlighter(),
          highlights = demo_highlights,
          separator = " | ",
        }),
      }),
    }
  end,
}

-- 11. Kind icons
scenes[#scenes + 1] = {
  name = "kind_icons",
  config = function()
    return {
      pipeline = w.branch(w.cmdline_pipeline({ fuzzy = true }), w.search_pipeline()),
      renderer = w.theme("auto").renderer({
        highlighter = w.fzy_highlighter(),
        highlights = demo_highlights,
        left = { " ", w.popupmenu_kind_icon() },
        right = { " ", w.popupmenu_scrollbar() },
      }),
    }
  end,
}

-- 12. Neon highlights (cyberpunk custom colors)
scenes[#scenes + 1] = {
  name = "hl_neon",
  config = function()
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
  end,
}

-- ── Scene switcher ──────────────────────────────────────────────

local current_scene = 1

local function apply_scene(index)
  local scene = scenes[index]
  if not scene then
    return
  end
  local cfg = scene.config()
  w.setup(vim.tbl_extend("force", {
    modes = { ":", "/", "?" },
    next_key = "<Tab>",
    previous_key = "<S-Tab>",
    accept_key = "<Down>",
    reject_key = "<Up>",
  }, cfg))
end

vim.keymap.set("n", "<C-n>", function()
  current_scene = current_scene + 1
  if current_scene > #scenes then
    current_scene = 1
  end
  apply_scene(current_scene)
end, { noremap = true, silent = true })

-- Apply first scene on startup
apply_scene(1)
