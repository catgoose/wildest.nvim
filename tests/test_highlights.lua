local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

T["setup_default_highlights()"] = new_set()

T["setup_default_highlights()"]["creates all expected highlight groups"] = function()
  local renderer = require("wildest.renderer")
  renderer.setup_default_highlights()

  local expected_groups = {
    "WildestDefault",
    "WildestSelected",
    "WildestAccent",
    "WildestSelectedAccent",
    "WildestBorder",
    "WildestPrompt",
    "WildestPromptCursor",
    "WildestScrollbar",
    "WildestScrollbarThumb",
    "WildestSpinner",
    "WildestError",
  }

  for _, group in ipairs(expected_groups) do
    local hl = vim.api.nvim_get_hl(0, { name = group })
    expect.equality(type(hl.link), "string", group .. " should be a link")
  end
end

T["setup_default_highlights()"]["links to correct default groups"] = function()
  local renderer = require("wildest.renderer")
  renderer.setup_default_highlights()

  local expected_links = {
    WildestDefault = "Pmenu",
    WildestSelected = "PmenuSel",
    WildestAccent = "PmenuMatch",
    WildestSelectedAccent = "PmenuMatchSel",
    WildestBorder = "FloatBorder",
    WildestPrompt = "Pmenu",
    WildestPromptCursor = "Cursor",
    WildestScrollbar = "PmenuSbar",
    WildestScrollbarThumb = "PmenuThumb",
    WildestSpinner = "Special",
    WildestError = "ErrorMsg",
  }

  for group, link_to in pairs(expected_links) do
    local hl = vim.api.nvim_get_hl(0, { name = group })
    expect.equality(hl.link, link_to, group .. " should link to " .. link_to)
  end
end

T["setup_default_highlights()"]["does not overwrite explicit theme highlights"] = function()
  -- Simulate a theme setting explicit colors before setup_default_highlights
  vim.api.nvim_set_hl(0, "WildestDefault", { bg = "#2A2A37", fg = "#DCD7BA" })
  vim.api.nvim_set_hl(0, "WildestBorder", { bg = "#1F1F28", fg = "#54546D" })

  local renderer = require("wildest.renderer")
  renderer.setup_default_highlights()

  -- Should NOT have been overwritten to a link
  local default_hl = vim.api.nvim_get_hl(0, { name = "WildestDefault" })
  expect.equality(default_hl.link, nil, "WildestDefault should not be a link after theme set it")
  expect.equality(default_hl.bg, 0x2A2A37)

  local border_hl = vim.api.nvim_get_hl(0, { name = "WildestBorder" })
  expect.equality(border_hl.link, nil, "WildestBorder should not be a link after theme set it")
  expect.equality(border_hl.bg, 0x1F1F28)
end

T["create_base_state()"] = new_set()

T["create_base_state()"]["defaults to Wildest highlight groups"] = function()
  local renderer = require("wildest.renderer")
  renderer.setup_default_highlights()

  local state = renderer.create_base_state({})
  expect.equality(state.highlights.default, "WildestDefault")
  expect.equality(state.highlights.selected, "WildestSelected")
  expect.equality(state.highlights.error, "WildestError")
end

T["create_base_state()"]["respects user-provided highlight overrides"] = function()
  local renderer = require("wildest.renderer")
  local state = renderer.create_base_state({
    hl = "MyCustomHl",
    selected_hl = "MyCustomSel",
    error_hl = "MyCustomErr",
  })
  expect.equality(state.highlights.default, "MyCustomHl")
  expect.equality(state.highlights.selected, "MyCustomSel")
  expect.equality(state.highlights.error, "MyCustomErr")
end

T["themes"] = new_set()

T["themes"]["theme highlights override defaults"] = function()
  local renderer = require("wildest.renderer")
  renderer.setup_default_highlights()

  -- Load kanagawa theme and apply it
  local themes = require("wildest.themes")
  local kanagawa = themes.kanagawa
  kanagawa.apply()

  -- Should have explicit colors, not links
  local hl = vim.api.nvim_get_hl(0, { name = "WildestDefault", link = false })
  expect.equality(hl.bg, 0x2A2A37)
  expect.equality(hl.fg, 0xDCD7BA)
end

T["themes"]["all built-in themes define required groups"] = function()
  local themes = require("wildest.themes")
  -- Core groups every theme must define
  local required_groups = {
    "WildestDefault",
    "WildestSelected",
    "WildestAccent",
    "WildestSelectedAccent",
  }

  for _, name in ipairs(themes.theme_names) do
    if name ~= "auto" then -- auto theme reads from colorscheme
      local ok, theme = pcall(require, "wildest.themes." .. name)
      if ok and theme and theme.get_def then
        local def = theme.get_def()
        for _, group in ipairs(required_groups) do
          local has_group = def.highlights and def.highlights[group] ~= nil
          expect.equality(has_group, true, name .. " theme should define " .. group)
        end
        -- Bordered/palette themes must also define WildestBorder
        if def.renderer == "border" or def.renderer == "palette" then
          local has_border = def.highlights and def.highlights.WildestBorder ~= nil
          expect.equality(has_border, true, name .. " theme should define WildestBorder")
        end
      end
    end
  end
end

return T
