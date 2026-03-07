local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

-- All built-in theme names (excluding auto which needs runtime colorscheme)
local theme_names = {
  "cactus",
  "catppuccin_frappe",
  "catppuccin_latte",
  "catppuccin_mocha",
  "default",
  "dracula",
  "dusty",
  "everforest_dark",
  "everforest_light",
  "gruvbox_dark",
  "gruvbox_light",
  "kanagawa",
  "kanagawa_dragon",
  "kanagawa_lotus",
  "midnight",
  "nightfox",
  "nord",
  "onedark",
  "outlaw",
  "prairie",
  "rose_pine",
  "rose_pine_dawn",
  "rose_pine_moon",
  "saloon",
  "solarized_dark",
  "sunset",
  "tokyonight_moon",
  "tokyonight_night",
  "tokyonight_storm",
  "tumbleweed",
  "wanted",
}

-- ── define structure ─────────────────────────────────────────────

T["define"] = new_set()

T["define"]["returns object with apply, renderer, get_def"] = function()
  local themes = require("wildest.themes")
  local theme = themes.define({
    highlights = { WildestDefault = { bg = "#000000" } },
  })
  expect.equality(type(theme.apply), "function")
  expect.equality(type(theme.renderer), "function")
  expect.equality(type(theme.get_def), "function")
end

T["define"]["get_def returns original definition"] = function()
  local themes = require("wildest.themes")
  local def = {
    highlights = { WildestDefault = { bg = "#111111" } },
    renderer = "popupmenu",
  }
  local theme = themes.define(def)
  local got = theme.get_def()
  expect.equality(got.renderer, "popupmenu")
  expect.equality(got.highlights.WildestDefault.bg, "#111111")
end

-- ── parametric theme validation ──────────────────────────────────

T["built-in themes"] = new_set()

T["built-in themes"]["all load without error"] = function()
  for _, name in ipairs(theme_names) do
    local ok, theme = pcall(require, "wildest.themes." .. name)
    expect.equality(ok, true)
    expect.equality(type(theme), "table")
  end
end

T["built-in themes"]["all have apply method"] = function()
  for _, name in ipairs(theme_names) do
    local theme = require("wildest.themes." .. name)
    expect.equality(type(theme.apply), "function")
  end
end

T["built-in themes"]["all have renderer method"] = function()
  for _, name in ipairs(theme_names) do
    local theme = require("wildest.themes." .. name)
    expect.equality(type(theme.renderer), "function")
  end
end

T["built-in themes"]["all have get_def method"] = function()
  for _, name in ipairs(theme_names) do
    local theme = require("wildest.themes." .. name)
    expect.equality(type(theme.get_def), "function")
  end
end

T["built-in themes"]["all define WildestDefault highlight"] = function()
  for _, name in ipairs(theme_names) do
    local theme = require("wildest.themes." .. name)
    local def = theme.get_def()
    expect.equality(type(def.highlights), "table")
    local hl = def.highlights.WildestDefault
    expect.equality(type(hl), "table")
  end
end

T["built-in themes"]["all define WildestSelected highlight"] = function()
  for _, name in ipairs(theme_names) do
    local theme = require("wildest.themes." .. name)
    local def = theme.get_def()
    local hl = def.highlights.WildestSelected
    expect.equality(type(hl), "table")
  end
end

T["built-in themes"]["renderer type is valid"] = function()
  local valid_renderers = { popupmenu = true, border = true, palette = true }
  for _, name in ipairs(theme_names) do
    local theme = require("wildest.themes." .. name)
    local def = theme.get_def()
    -- renderer defaults to "border" if not specified
    local renderer = def.renderer or "border"
    expect.equality(valid_renderers[renderer] ~= nil, true)
  end
end

-- ── extend ───────────────────────────────────────────────────────

T["extend"] = new_set()

T["extend"]["merges highlights from override"] = function()
  local themes = require("wildest.themes")
  local base = themes.define({
    highlights = {
      WildestDefault = { bg = "#000000", fg = "#ffffff" },
      WildestSelected = { bg = "#111111" },
    },
  })
  local extended = themes.extend(base, {
    highlights = {
      WildestDefault = { bg = "#222222" },
    },
  })
  local def = extended.get_def()
  expect.equality(def.highlights.WildestDefault.bg, "#222222")
  -- Selected should still exist from base
  expect.equality(type(def.highlights.WildestSelected), "table")
end

return T
